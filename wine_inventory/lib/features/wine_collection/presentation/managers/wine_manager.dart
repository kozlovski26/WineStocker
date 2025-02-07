import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';
import 'package:wine_inventory/core/models/wine_type.dart';  // Fixed import path
import '../dialogs/first_time_setup_dialog.dart';

class WineManager extends ChangeNotifier {
  final WineRepository repository;
  List<List<WineBottle>> _grid;
  List<WineBottle> drunkWines = [];
  late GridSettings settings;
  WineType? _selectedFilter;
  int totalBottles = 0;
  double totalCollectionValue = 0.0;
  bool isGridView = true;
  bool _isLoading = false;
  bool _isInitialized = false;
  WineBottle? _copiedWine;
  int _copiedWineRow = -1;
  int _copiedWineCol = -1;

  // Getters
  List<List<WineBottle>> get grid => _grid;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasCopiedWine => _copiedWine != null;
  WineType? get selectedFilter => _selectedFilter;
  WineBottle? get copiedWine => _copiedWine;

  WineManager(this.repository) :
    _grid = [],
    settings = GridSettings.defaultSettings() {
    loadData();
  }

  void _initializeGrid() {
    _grid = List.generate(
      settings.rows,
      (i) => List.generate(
        settings.columns,
        (j) => WineBottle(),
      ),
    );
  }

  bool _isValidPosition(int row, int col) {
    return _grid.isNotEmpty &&
           row >= 0 &&
           col >= 0 &&
           row < _grid.length &&
           _grid[row].isNotEmpty &&
           col < _grid[row].length;
  }

  Future<void> loadData() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _isInitialized = false;
      notifyListeners();

      settings = await repository.loadGridSettings();
      _initializeGrid();

      final existingGrid = await repository.loadWineGrid(settings);
      if (existingGrid.isNotEmpty) {
        for (int i = 0; i < settings.rows && i < existingGrid.length; i++) {
          for (int j = 0; j < settings.columns && j < existingGrid[i].length; j++) {
            if (!existingGrid[i][j].isEmpty) {
              _grid[i][j] = existingGrid[i][j];
            }
          }
        }
      }

      drunkWines = await repository.loadDrunkWines();
      _updateStatistics();

    } catch (e) {
      print('Error loading data: $e');
      _initializeGrid();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> saveSettings(GridSettings newSettings) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      settings = newSettings;
      await repository.saveGridSettings(settings);
      await loadData();
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> showFirstTimeSetup(BuildContext context) async {
    final isFirstTime = await repository.isFirstTimeSetup();
    if (!isFirstTime) return false;

    final newSettings = await showDialog<GridSettings>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FirstTimeSetupDialog(),
    );

    if (newSettings != null) {
      settings = newSettings;
      await repository.saveGridSettings(settings);
      await loadData();
      return true;
    }
    return false;
  }

  void setFilter(WineType? type) {
    _selectedFilter = (_selectedFilter == type) ? null : type;
    _updateStatistics();
    notifyListeners();
  }

  void toggleView() {
    isGridView = !isGridView;
    notifyListeners();
  }

  void _updateStatistics() {
    if (_grid.isEmpty) {
      totalBottles = 0;
      totalCollectionValue = 0;
      return;
    }

    int bottles = 0;
    double total = 0;

    for (var row in _grid) {
      for (var bottle in row) {
        if (!bottle.isEmpty &&
            (_selectedFilter == null || bottle.type == _selectedFilter)) {
          bottles++;
          if (bottle.price != null) {
            total += bottle.price!;
          }
        }
      }
    }

    totalBottles = bottles;
    totalCollectionValue = total;
    notifyListeners();
  }

  Future<void> copyWine(WineBottle bottle, int row, int col) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create initial copy
      _copiedWine = WineBottle(
        name: bottle.name,
        winery: bottle.winery,
        year: bottle.year,
        notes: bottle.notes,
        type: bottle.type,
        rating: bottle.rating,
        price: bottle.price,
        isFavorite: bottle.isFavorite,
        isForTrade: bottle.isForTrade,
        ownerId: bottle.ownerId,
        dateAdded: DateTime.now(),
        imagePath: bottle.imagePath  // Store the original image path
      );

      _copiedWineRow = row;
      _copiedWineCol = col;
      
      print('Wine copy completed successfully with image: ${_copiedWine?.imagePath}');

    } catch (e) {
      print('Error copying wine: $e');
      _copiedWine = null;
      _copiedWineRow = -1;
      _copiedWineCol = -1;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pasteWine(int row, int col) async {
    if (!_isValidPosition(row, col) || _copiedWine == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final batch = repository.firestore.batch();
      final winesCollection = repository.firestore
          .collection('users')
          .doc(repository.userId)
          .collection('wines');

      // Handle existing wine at target position
      final existingSnapshot = await winesCollection
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      for (var doc in existingSnapshot.docs) {
        final oldData = doc.data();
        if (oldData['imagePath'] != null) {
          await repository.deleteWineImage(oldData['imagePath']);
        }
        batch.delete(doc.reference);
      }

      // Create new wine document
      String? newImageUrl;
      if (_copiedWine!.imagePath != null && _copiedWine!.imagePath!.startsWith('http')) {
        print('Copying image from source: ${_copiedWine!.imagePath}');
        newImageUrl = await repository.copyWineImage(_copiedWine!.imagePath!);
        print('New image URL: $newImageUrl');
      }

      final newWine = WineBottle(
        name: _copiedWine!.name,
        winery: _copiedWine!.winery,
        year: _copiedWine!.year,
        notes: _copiedWine!.notes,
        type: _copiedWine!.type,
        rating: _copiedWine!.rating,
        price: _copiedWine!.price,
        isFavorite: _copiedWine!.isFavorite,
        isForTrade: _copiedWine!.isForTrade,
        ownerId: repository.userId,
        dateAdded: DateTime.now(),
        imagePath: newImageUrl ?? _copiedWine!.imagePath
      );

      // Create the new document
      final newDocRef = winesCollection.doc();
      batch.set(newDocRef, {
        ...newWine.toJson(),
        'position': {'row': row, 'col': col},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit changes
      await batch.commit();

      // Update local state
      _grid[row][col] = newWine;
      _updateStatistics();

      // Force a refresh of the grid data
      await loadData();

    } catch (e) {
      print('Error pasting wine: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWine(WineBottle bottle, int row, int col) async {
    if (!_isValidPosition(row, col)) return;

    try {
      _isLoading = true;
      notifyListeners();

      final batch = repository.firestore.batch();
      final winesCollection = repository.firestore
          .collection('users')
          .doc(repository.userId)
          .collection('wines');

      // First, find and delete any existing wines at this position
      final existingSnapshot = await winesCollection
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      for (var doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Create new document
      final newDocRef = winesCollection.doc();
      batch.set(newDocRef, {
        ...bottle.toJson(),
        'position': {'row': row, 'col': col},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit all changes
      await batch.commit();

      // Update local state
      _grid[row][col] = bottle;
      _updateStatistics();
      notifyListeners(); // Notify listeners after updating local state

    } catch (e) {
      print('Error updating wine: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsDrunk(WineBottle bottle, int row, int col) async {
    if (!_isValidPosition(row, col)) return;

    try {
      _isLoading = true;
      notifyListeners();

      final batch = repository.firestore.batch();

      // Create drunk wine document
      final drunkWineRef = repository.firestore
          .collection('users')
          .doc(repository.userId)
          .collection('drunk_wines')
          .doc();

      final drunkBottle = WineBottle(
        name: bottle.name,
        winery: bottle.winery,
        year: bottle.year,
        notes: bottle.notes,
        type: bottle.type,
        imagePath: bottle.imagePath,
        rating: bottle.rating,
        price: bottle.price,
        dateAdded: bottle.dateAdded,
        isDrunk: true,
        dateDrunk: DateTime.now(),
        isFavorite: bottle.isFavorite,
        isForTrade: false,
        ownerId: bottle.ownerId
      );

      batch.set(drunkWineRef, {
        ...drunkBottle.toJson(),
        'drunkAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Delete from main collection
      final snapshot = await repository.firestore
          .collection('users')
          .doc(repository.userId)
          .collection('wines')
          .where('position.row', isEqualTo: row)
          .where('position.col', isEqualTo: col)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit all changes
      await batch.commit();

      // Update local state
      drunkWines.add(drunkBottle);
      _grid[row][col] = WineBottle();
      _updateStatistics();

    } catch (e) {
      print('Error marking wine as drunk: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWine(int row, int col) async {
    if (!_isValidPosition(row, col)) return;

    try {
      _isLoading = true;
      notifyListeners();

      final bottle = _grid[row][col];
      
      // Delete from Firestore
      await repository.deleteWineFromFirestore(row, col);

      // Delete image if it exists
      if (!bottle.isEmpty && bottle.imagePath != null && bottle.imagePath!.startsWith('http')) {
        await repository.deleteWineImage(bottle.imagePath!);
      }
      
      // Clear the grid position
      _grid[row][col] = WineBottle();
      _updateStatistics();

    } catch (e) {
      print('Error deleting wine: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDrunkWine(WineBottle wine) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      drunkWines.remove(wine);
      await repository.removeDrunkWine(wine);
      await saveData();
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveData() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Remove any drunk wines from the grid
      for (int i = 0; i < _grid.length; i++) {
        for (int j = 0; j < _grid[i].length; j++) {
          if (_grid[i][j].isDrunk) {
            _grid[i][j] = WineBottle();
          }
        }
      }
      
      // Save wine grid and drunk wines
      await Future.wait([
        repository.saveWineGrid(_grid),
        repository.saveDrunkWines(drunkWines)
      ]);
      
      _updateStatistics();
      
    } catch (e) {
      print('Error in saveData: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<WineBottle> getVisibleBottles() {
    if (_grid.isEmpty) return [];

    return _grid.expand((row) => row)
        .where((bottle) => !bottle.isEmpty && 
            (_selectedFilter == null || bottle.type == _selectedFilter))
        .toList();
  }

  Future<void> clearCopiedWine() async {
    _copiedWine = null;
    _copiedWineRow = -1;
    _copiedWineCol = -1;
    notifyListeners();
  }

  @override
  void dispose() {
    _grid.clear();
    drunkWines.clear();
    _copiedWine = null;
    super.dispose();
  }
}