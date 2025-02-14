import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  FirebaseFirestore get firestore => _firestore;
  final String userId;

  WineRepository(this.userId);

  // Collection References
  CollectionReference get _userWines => 
    _firestore.collection('users').doc(userId).collection('wines');
  CollectionReference get _userSettings => 
    _firestore.collection('users').doc(userId).collection('settings');
  CollectionReference get _drunkWines =>
    _firestore.collection('users').doc(userId).collection('drunk_wines');

  // Wine Document Operations
  Future<DocumentReference<Map<String, dynamic>>?> getWineDocument(int row, int col) async {
    try {
      final snapshot = await _userWines
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.reference.withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        );
      }
      return null;
    } catch (e) {
      print('Error getting wine document: $e');
      rethrow;
    }
  }

  Future<void> updateWinePosition(WineBottle bottle, int row, int col) async {
    try {
      final snapshot = await _userWines
          .where('name', isEqualTo: bottle.name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'position': {'row': row, 'col': col},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating wine position: $e');
      rethrow;
    }
  }

  // Grid Operations
  Future<void> saveWineToPosition(WineBottle bottle, int row, int col) async {
    try {
      final batch = _firestore.batch();
      
      // Delete existing wine at position
      final existingSnapshot = await _userWines
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      for (var doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new wine
      batch.set(_userWines.doc(), {
        ...bottle.toJson(),
        'position': {'row': row, 'col': col},
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print('Error saving wine to position: $e');
      rethrow;
    }
  }

  Future<void> deleteWineFromFirestore(int row, int col) async {
    try {
      final snapshot = await _userWines
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting wine from Firestore: $e');
      rethrow;
    }
  }

  Future<void> saveWineGrid(List<List<WineBottle>> grid) async {
    try {
      final batch = _firestore.batch();
      
      // Delete all existing wines
      final existingWines = await _userWines.get();
      for (var doc in existingWines.docs) {
        batch.delete(doc.reference);
      }

      // Add all wines from grid
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          final bottle = grid[i][j];
          if (!bottle.isEmpty) {
            batch.set(_userWines.doc(), {
              ...bottle.toJson(),
              'position': {'row': i, 'col': j},
              'userId': userId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error saving complete grid: $e');
      rethrow;
    }
  }

  Future<List<List<WineBottle>>> loadWineGrid(GridSettings settings) async {
    try {
      final snapshot = await _userWines
          .where('isDrunk', isEqualTo: false)
          .get();
      
      List<List<WineBottle>> grid = List.generate(
        settings.rows,
        (i) => List.generate(settings.columns, (j) => WineBottle()),
      );

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final position = data['position'] as Map<String, dynamic>?;
        
        if (position != null) {
          final row = position['row'] as int?;
          final col = position['col'] as int?;

          if (row != null && col != null && 
              row >= 0 && row < settings.rows && 
              col >= 0 && col < settings.columns) {
            grid[row][col] = WineBottle.fromJson(data);
          }
        }
      }

      return grid;
    } catch (e) {
      print('Error loading grid: $e');
      rethrow;
    }
  }

  Future<List<List<WineBottle>>> loadUserWineGrid(String otherUserId, GridSettings settings) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('wines')
          .where('isDrunk', isEqualTo: false)
          .get();
      
      List<List<WineBottle>> grid = List.generate(
        settings.rows,
        (i) => List.generate(settings.columns, (j) => WineBottle()),
      );

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final position = data['position'] as Map<String, dynamic>?;
        
        if (position != null) {
          final row = position['row'] as int?;
          final col = position['col'] as int?;

          if (row != null && col != null && 
              row >= 0 && row < settings.rows && 
              col >= 0 && col < settings.columns) {
            grid[row][col] = WineBottle.fromJson(data);
          }
        }
      }

      return grid;
    } catch (e) {
      print('Error loading user wine grid: $e');
      rethrow;
    }
  }

  // Image Operations
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

  Future<String?> copyWineImage(String sourceUrl) async {
    try {
      final fileName = 'wine_copy_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newRef = _storage.ref().child('users/$userId/wine_images/$fileName');
      
      final sourceRef = FirebaseStorage.instance.refFromURL(sourceUrl);
      final downloadUrl = await sourceRef.getDownloadURL();
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download source image');
      }

      await newRef.putData(
        response.bodyBytes,
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

  Future<bool> deleteWineImage(String? imageUrl) async {
    if (imageUrl == null || !imageUrl.startsWith('http')) return true;

    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      if (e.toString().contains('object-not-found')) return true;
      print('Error deleting image: $e');
      return false;
    }
  }

  // Drunk Wines Operations
  Future<void> saveDrunkWines(List<WineBottle> drunkWines) async {
    try {
      final writeBatch = _firestore.batch();

      for (var bottle in drunkWines) {
        writeBatch.set(_drunkWines.doc(), {
          ...bottle.toJson(),
          'isDrunk': true,
          'isDeleted': false,
          'userId': userId,
          'dateDrunk': bottle.dateDrunk?.toIso8601String(),
          'drunkAt': bottle.dateDrunk?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await writeBatch.commit();
    } catch (e) {
      print('Error saving drunk wines: $e');
      rethrow;
    }
  }

  Future<List<WineBottle>> loadDrunkWines() async {
    try {
      // First query by drunkAt only
      final snapshot = await _drunkWines
          .orderBy('drunkAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Only return non-deleted wines
            if (data['isDeleted'] == true) {
              return null;
            }
            return WineBottle.fromJson(data);
          })
          .where((bottle) => bottle != null && bottle.name != null)
          .cast<WineBottle>()
          .toList();
    } catch (e) {
      print('Error loading drunk wines: $e');
      rethrow;
    }
  }

  Future<void> removeDrunkWine(WineBottle wine) async {
    try {
      final snapshot = await _drunkWines
          .where('name', isEqualTo: wine.name)
          .where('drunkAt', isEqualTo: wine.dateDrunk?.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error removing drunk wine: $e');
      rethrow;
    }
  }

  // Settings Operations
  Future<void> saveGridSettings(GridSettings settings) async {
    try {
      await _userSettings.doc('grid').set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving grid settings: $e');
      rethrow;
    }
  }

  Future<GridSettings> loadGridSettings() async {
    try {
      final doc = await _userSettings.doc('grid').get();
      if (doc.exists) {
        return GridSettings.fromJson(doc.data() as Map<String, dynamic>);
      }
      return GridSettings.defaultSettings();
    } catch (e) {
      print('Error loading grid settings: $e');
      rethrow;
    }
  }

  Future<void> markFirstTimeSetupComplete() async {
    try {
      await _userSettings.doc('setup').set({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking first time setup complete: $e');
      rethrow;
    }
  }

  Future<bool> isFirstTimeSetup() async {
    try {
      // First check if grid settings exist
      final gridDoc = await _userSettings.doc('grid').get();
      if (gridDoc.exists) {
        // If grid settings exist, user has already set up their collection
        return false;
      }
      
      // Check if there are any existing wines
      final winesSnapshot = await _userWines.limit(1).get();
      if (winesSnapshot.docs.isNotEmpty) {
        // If there are existing wines, user has already set up their collection
        return false;
      }

      // If no grid settings and no wines exist, it's first time setup
      return true;
    } catch (e) {
      print('Error checking first time setup: $e');
      // In case of error, assume it's not first time to prevent data loss
      return false;
    }
  }

  Future<bool> isUserPro() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['isPro'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking pro status: $e');
      return false;
    }
  }

  // User Profile Operations
  Future<Map<String, dynamic>> getUserData() async {
    try {
      print('Getting user data for userId: $userId'); // Debug log
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) {
        print('No user document found, creating default'); // Debug log
        // Create default user document if it doesn't exist
        final defaultData = {
          'userId': userId,
          'displayName': '',
          'photoURL': null,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('users')
            .doc(userId)
            .set(defaultData);
            
        return defaultData;
      }
      
      final data = docSnapshot.data() ?? {};
      print('Retrieved user data: $data'); // Debug log
      return data;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(String localPath) async {
    try {
      print('Starting profile image upload for userId: $userId');
      
      // Verify authorization
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('User not authorized');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        print('File does not exist: $localPath');
        return null;
      }

      // Create a unique filename
      final ext = localPath.split('.').last.toLowerCase();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'users/$userId/profile/$fileName';
      final ref = _storage.ref().child(path);
      
      print('Uploading new image to path: $path');

      // Upload new image with metadata
      final metadata = SettableMetadata(
        contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final uploadTask = ref.putFile(file, metadata);
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Wait for upload to complete
      await uploadTask;
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');
      
      // Update Firestore with new image URL
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error uploading profile image: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      print('Updating user profile for userId: $userId');
      print('New photo URL: $photoURL'); // Debug log
      
      // Get current user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentData = userDoc.data() ?? {};
      
      // Prepare update data while preserving existing fields
      final Map<String, dynamic> userData = {
        ...currentData,
        'updatedAt': FieldValue.serverTimestamp(),
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      };

      print('Updating Firestore with data: $userData'); // Debug log

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));

      // Update Firebase Auth profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateProfile(
          displayName: displayName ?? user.displayName,
          photoURL: photoURL ?? user.photoURL,
        );
        print('Updated Firebase Auth profile'); // Debug log
      }

    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> toggleUserProStatus(String userId, bool isPro) async {
    try {
      // First check if the user document exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        // Create user document with default fields if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'userId': userId,
          'isPro': isPro,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing document
        await _firestore.collection('users').doc(userId).update({
          'isPro': isPro,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling pro status: $e');
      rethrow;
    }
  }
}
