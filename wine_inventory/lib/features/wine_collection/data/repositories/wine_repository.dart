import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';

class WineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String userId;

  WineRepository(this.userId);

  CollectionReference get _userWines => 
    _firestore.collection('users').doc(userId).collection('wines');
  
  CollectionReference get _userSettings => 
    _firestore.collection('users').doc(userId).collection('settings');

  CollectionReference get _drunkWines =>
    _firestore.collection('users').doc(userId).collection('drunk_wines');

  Future<String?> uploadWineImage(String localPath) async {
    try {
      final file = File(localPath);
      final fileName = 'wine_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/wine_images/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> deleteWineImage(String? imageUrl) async {
    if (imageUrl == null || !imageUrl.startsWith('http')) {
      return true;  // Nothing to delete
    }

    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        return true;  // Consider it a success if image doesn't exist
      }
      print('Error deleting image: $e');
      return false;
    }
  }
 Future<void> deleteWineFromFirestore(int row, int col) async {
    try {
      // Get the document reference from Firestore
      final snapshot = await _userWines
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      // Delete the document from Firestore
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting wine from Firestore: $e');
      rethrow;
    }
  }
 Future<String?> copyWineImage(String sourceUrl) async {
  try {
    // Get reference to the source image
    final sourceRef = FirebaseStorage.instance.refFromURL(sourceUrl);
    
    // Create a new filename for the copy
    final fileName = 'wine_copy_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newRef = _storage.ref().child('users/$userId/wine_images/$fileName');
    
    // Download source image data
    final data = await sourceRef.getData();
    if (data == null) return null;
    
    // Upload to new location with metadata
    await newRef.putData(
      data,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'copiedAt': DateTime.now().toIso8601String(),
          'sourceUrl': sourceUrl,
        },
      ),
    );
    
    return await newRef.getDownloadURL();
  } catch (e) {
    print('Error copying image: $e');
    return null;
  }
}

  Future<void> saveWineGrid(List<List<WineBottle>> grid) async {
  final batch = _firestore.batch();
  
  // Get existing wines and their images
  final existingWines = await _userWines.get();
  final existingImages = existingWines.docs
      .map((doc) => (doc.data() as Map<String, dynamic>)['imagePath'] as String?)
      .where((url) => url != null)
      .toList();
  
  // Track which images are still in use
  final imagesInUse = <String>{};
  
  // Delete existing docs
  for (var doc in existingWines.docs) {
    batch.delete(doc.reference);
  }

  // Add new wines
  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      final bottle = grid[i][j];
      
      // Skip empty bottles
      if (bottle.isEmpty) continue;

      String? imageUrl = bottle.imagePath;
      
      // Upload new image if needed
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        imageUrl = await uploadWineImage(bottle.imagePath!);
        bottle.imagePath = imageUrl;
      }
      
      // Track image if it exists
      if (imageUrl != null && imageUrl.startsWith('http')) {
        imagesInUse.add(imageUrl);
      }

      // Create Firestore document with position
      batch.set(_userWines.doc(), {
        ...bottle.toJson(),
        'position': {'row': i, 'col': j},
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete unused images
  for (String? oldImage in existingImages) {
    if (oldImage != null && !imagesInUse.contains(oldImage)) {
      await deleteWineImage(oldImage);
    }
  }

  await batch.commit();
}

  Future<List<List<WineBottle>>> loadWineGrid(GridSettings settings) async {
  final snapshot = await _userWines
      .where('isDrunk', isEqualTo: false)  // Only load wines that are not marked as drunk
      .get();
  
  List<List<WineBottle>> grid = List.generate(
    settings.rows,
    (i) => List.generate(settings.columns, (j) => WineBottle()),
  );

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final position = data['position'] as Map<String, dynamic>?;
    
    // Skip if position is missing or null
    if (position == null) continue;

    final row = position['row'] as int?;
    final col = position['col'] as int?;

    // Validate row and column
    if (row == null || col == null) continue;
    if (row < 0 || row >= settings.rows || col < 0 || col >= settings.columns) continue;

    grid[row][col] = WineBottle.fromJson(data);
  }

  return grid;
}
  Future<void> saveDrunkWines(List<WineBottle> drunkWines) async {
  final writeBatch = _firestore.batch();

  try {
    // Remove wines from main collection
    final winesSnapshot = await _userWines
        .where('isDrunk', isEqualTo: true)
        .get();

    // Delete existing marked wines from wines collection
    for (var doc in winesSnapshot.docs) {
      writeBatch.delete(doc.reference);
    }

    // Add to drunk wines collection
    for (var bottle in drunkWines) {
      final drunkWineData = {
        ...bottle.toJson(),
        'userId': userId,
        'drunkAt': bottle.dateDrunk?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      writeBatch.set(_drunkWines.doc(), drunkWineData);
    }

    // Commit the batch
    await writeBatch.commit();

    print('Saved ${drunkWines.length} wines to drunk_wines collection');
  } catch (e) {
    print('Error saving drunk wines: $e');
    rethrow;
  }
}

  Future<List<WineBottle>> loadDrunkWines() async {
    final snapshot = await _drunkWines
        .orderBy('drunkAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WineBottle.fromJson(doc.data() as Map<String, dynamic>))
        .where((bottle) => bottle.isDrunk && bottle.dateDrunk != null)
        .toList();
  }

  Future<void> removeDrunkWine(WineBottle wine) async {
    try {
      final snapshot = await _drunkWines
          .where('name', isEqualTo: wine.name)
          .where('drunkAt', isEqualTo: wine.dateDrunk?.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['imagePath'] != null) {
          await deleteWineImage(data['imagePath']);
        }
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error removing drunk wine: $e');
      rethrow;
    }
  }

  Future<void> saveGridSettings(GridSettings settings) async {
    await _userSettings.doc('grid').set({
      ...settings.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
Future<bool> isFirstTimeSetup() async {
  final doc = await _userSettings.doc('grid').get();
  return !doc.exists;
}

  Future<GridSettings> loadGridSettings() async {
    final doc = await _userSettings.doc('grid').get();
    if (doc.exists) {
      return GridSettings.fromJson(doc.data() as Map<String, dynamic>);
    }
    return GridSettings.defaultSettings();
  }

  Future<List<List<WineBottle>>> loadUserWineGrid(
    String otherUserId, 
    GridSettings settings
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('wines')
        .orderBy('createdAt', descending: false)
        .get();

    List<List<WineBottle>> grid = List.generate(
      settings.rows,
      (i) => List.generate(settings.columns, (j) => WineBottle()),
    );

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final position = data['position'] as Map<String, dynamic>;
      final row = position['row'] as int;
      final col = position['col'] as int;

      if (row < settings.rows && col < settings.columns) {
        grid[row][col] = WineBottle.fromJson(data);
      }
    }

    return grid;
  }
}