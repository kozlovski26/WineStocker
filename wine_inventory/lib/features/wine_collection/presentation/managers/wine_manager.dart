import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';
import 'package:wine_inventory/core/models/wine_type.dart';  // Fixed import path
import '../dialogs/first_time_setup_dialog.dart';
import 'package:wine_inventory/core/models/currency.dart'; 
import 'dart:io';

class Position {
  final int row;
  final int col;
  
  Position(this.row, this.col);
}

class WineManager extends ChangeNotifier {
  final WineRepository repository;
  List<List<WineBottle>> _grid = [];
  List<WineBottle> drunkWines = [];
  late GridSettings settings;
  WineType? _selectedFilter;
  int totalBottles = 0;
  double totalCollectionValue = 0.0;
  // Always be in grid view mode
  bool isGridView = true;
  bool _isLoading = false;
  bool _isGridLoading = false;
  bool _isInitialized = false;
  WineBottle? _copiedWine;
  int _copiedWineRow = -1;
  int _copiedWineCol = -1;
  bool isDragMode = false;
  Position? copiedWinePosition;

  // Add debounce timer
  Timer? _loadingDebounceTimer;

  // Getters
  List<List<WineBottle>> get grid => _grid;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isGridLoading => _isGridLoading;
  bool get hasCopiedWine => _copiedWine != null;
  WineType? get selectedFilter => _selectedFilter;

  WineManager(this.repository) {
    settings = GridSettings.defaultSettings();
    loadData();
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

  void setFilter(WineType? type) {
    _selectedFilter = type;
    notifyListeners();
  }

  void copyWine(WineBottle bottle, int row, int col) {
    _copiedWine = bottle.copyWith();
    _copiedWineRow = row;
    _copiedWineCol = col;
    copiedWinePosition = Position(row, col);
    notifyListeners();
  }

  Future<void> pasteWine(int row, int col) async {
    if (_copiedWine == null) return;

    try {
      _setGridLoading(true);

      final newBottle = WineBottle(
        name: _copiedWine!.name,
        winery: _copiedWine!.winery,
        type: _copiedWine!.type,
        year: _copiedWine!.year,
        price: _copiedWine!.price,
        rating: _copiedWine!.rating,
        notes: _copiedWine!.notes,
        imagePath: _copiedWine!.imagePath,
        dateAdded: _copiedWine!.dateAdded,
        dateDrunk: _copiedWine!.dateDrunk,
        isFavorite: _copiedWine!.isFavorite,
        isDrunk: _copiedWine!.isDrunk,
        ownerId: _copiedWine!.ownerId,
        isForTrade: _copiedWine!.isForTrade,
      );

      // Update the grid first
      _grid[row][col] = newBottle;
      
      // Then save to repository
      await repository.saveWineGrid(_grid);
      _updateStatistics();

    } catch (e) {
      print('Error pasting wine: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
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

  void _updateStatistics() {
    totalBottles = 0;
    totalCollectionValue = 0.0;

    for (var row in _grid) {
      for (var bottle in row) {
        if (!bottle.isEmpty) {
          totalBottles++;
          totalCollectionValue += bottle.price ?? 0;
        }
      }
    }
  }

  Future<void> deleteWine(int row, int col) async {
    try {
      _setGridLoading(true);

      _grid[row][col] = WineBottle();
      await repository.saveWineGrid(_grid);
      _updateStatistics();

    } catch (e) {
      print('Error deleting wine: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
  }

  Future<void> markAsDrunk(WineBottle bottle, int row, int col, {File? eventPhotoFile}) async {
    try {
      _setGridLoading(true);

      // Create a copy with the event's details
      final drunkBottle = bottle.copyWith(
        isDrunk: true,
        dateDrunk: DateTime.now(),
      );

      // Upload event photo if provided
      String? eventPhotoUrl;
      if (eventPhotoFile != null) {
        eventPhotoUrl = await repository.uploadWineImage(eventPhotoFile.path);
        if (eventPhotoUrl != null) {
          // Store the event photo URL in metadata
          Map<String, dynamic> updatedMetadata = {};
          if (drunkBottle.metadata != null) {
            updatedMetadata = Map<String, dynamic>.from(drunkBottle.metadata!);
          }
          updatedMetadata['eventPhotoUrl'] = eventPhotoUrl;
          drunkBottle.metadata = updatedMetadata;
        }
      }

      // Add to local drunk wines list
      drunkWines.add(drunkBottle);
      // Remove from grid
      _grid[row][col] = WineBottle();
      
      await Future.wait([
        repository.saveWineGrid(_grid),
        repository.saveDrunkWines([drunkBottle]) // Only save the new drunk wine
      ]);
      
      _updateStatistics();

    } catch (e) {
      print('Error marking wine as drunk: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
  }

  Future<void> addDrunkWine(WineBottle bottle, {File? imageFile, File? eventPhotoFile}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Ensure dateDrunk is set
      if (bottle.dateDrunk == null) {
        bottle = bottle.copyWith(dateDrunk: DateTime.now());
      }
      
      // Ensure isDrunk is set
      if (!bottle.isDrunk) {
        bottle = bottle.copyWith(isDrunk: true);
      }
      
      // Upload bottle image if available
      if (imageFile != null) {
        final imageUrl = await repository.uploadWineImage(imageFile.path);
        if (imageUrl != null) {
          bottle = bottle.copyWith(imagePath: imageUrl);
        }
      }
      
      // Upload event photo if available
      if (eventPhotoFile != null) {
        final eventPhotoUrl = await repository.uploadWineImage(eventPhotoFile.path);
        if (eventPhotoUrl != null) {
          // Add the event photo URL to the wine's metadata
          final updatedMetadata = {...bottle.metadata ?? {}, 'eventPhotoUrl': eventPhotoUrl};
          bottle = bottle.copyWith(metadata: updatedMetadata);
        }
      }
      
      drunkWines.add(bottle);
      await repository.saveDrunkWines([bottle]); // Only save the new drunk wine
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDrunkWine(WineBottle updatedWine) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the index of the wine to update
      final index = drunkWines.indexWhere((wine) => 
          wine.name == updatedWine.name && 
          wine.winery == updatedWine.winery &&
          wine.dateDrunk == updatedWine.dateDrunk);
      
      if (index != -1) {
        final oldWine = drunkWines[index];
        // Replace the wine at the found index
        drunkWines[index] = updatedWine;
        // Update in repository using the new method
        await repository.updateDrunkWine(oldWine, updatedWine);
      } else {
        throw Exception('Wine not found in drunk wines list');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveSettings(GridSettings newSettings) async {
    try {
      _setGridLoading(true);

      settings = newSettings;
      await repository.saveGridSettings(settings);
      await loadData();
      
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
  }

  Future<bool> showFirstTimeSetup(BuildContext context) async {
    final isFirstTime = await repository.isFirstTimeSetup();
    if (!isFirstTime) return false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FirstTimeSetupDialog(),
    );

    if (result != null) {
      // Set loading state
      _isLoading = true;
      notifyListeners();

      try {
        settings = result['settings'] as GridSettings;
        _grid = result['grid'] as List<List<WineBottle>>;
        
        // Save both settings and grid
        await Future.wait([
          repository.saveGridSettings(settings),
          repository.saveWineGrid(_grid),
          repository.markFirstTimeSetupComplete(),  // Mark setup as complete
        ]);

        // Update statistics and notify listeners
        _updateStatistics();
        _isInitialized = true;
        return true;
      } catch (e) {
        print('Error in first time setup: $e');
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
    return false;
  }

  void toggleDragMode() {
    isDragMode = !isDragMode;
    notifyListeners();
  }

  bool _isValidPosition(int row, int col) {
    return _grid.isNotEmpty &&
           row >= 0 &&
           col >= 0 &&
           row < _grid.length &&
           _grid[row].isNotEmpty &&
           col < _grid[row].length;
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

      // Check if the wine image needs to be uploaded
      if (bottle.imagePath != null && !bottle.imagePath!.startsWith('http')) {
        final uploadedUrl = await repository.uploadWineImage(bottle.imagePath!);
        bottle.imagePath = uploadedUrl;
      }

      // Create new document with the updated wine details
      final newDocRef = winesCollection.doc();
      batch.set(newDocRef, {
        ...bottle.toJson(),
        'position': {'row': row, 'col': col},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit all changes
      await batch.commit();

      // Update local state immediately
      _grid[row][col] = bottle;
      _updateStatistics();
      notifyListeners();

    } catch (e) {
      print('Error updating wine: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDrunkWine(WineBottle wine, {bool markAsDeleted = false}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (markAsDeleted) {
        // Update in Firestore
        final snapshot = await repository.firestore
            .collection('users')
            .doc(repository.userId)
            .collection('drunk_wines')
            .where('dateDrunk', isEqualTo: wine.dateDrunk?.toIso8601String())
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.update({'isDeleted': true});
        }
      } else {
        // Completely remove from Firestore
        await repository.removeDrunkWine(wine);
      }
      
      drunkWines.remove(wine);
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
      
      // Only save wine grid - drunk wines are managed separately
      await repository.saveWineGrid(_grid);
      
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
    copiedWinePosition = null;
    notifyListeners();
  }

  // Helper method to set loading state with debounce
  void _setGridLoading(bool loading) {
    _loadingDebounceTimer?.cancel();
    if (loading) {
      _isGridLoading = true;
      notifyListeners();
    } else {
      _loadingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _isGridLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> restoreWine(WineBottle wine) async {
    try {
      _setGridLoading(true);
      
      // Find first empty slot in grid
      int? targetRow;
      int? targetCol;
      
      for (int i = 0; i < _grid.length; i++) {
        for (int j = 0; j < _grid[i].length; j++) {
          if (_grid[i][j].isEmpty) {
            targetRow = i;
            targetCol = j;
            break;
          }
        }
        if (targetRow != null) break;
      }
      
      if (targetRow == null || targetCol == null) {
        throw Exception('No empty slots available in grid');
      }
      
      // Create restored wine with updated properties
      final restoredWine = wine.copyWith(
        isDrunk: false,
        dateDrunk: null,
        dateAdded: DateTime.now(),
      );
      
      // Update grid
      _grid[targetRow][targetCol] = restoredWine;
      
      // Remove from drunk wines list locally
      drunkWines.remove(wine);
      
      // Save changes - save grid and remove from drunk wines in Firestore
      await Future.wait([
        repository.saveWineGrid(_grid),
        repository.removeDrunkWine(wine)
      ]);
      
      _updateStatistics();
      
    } catch (e) {
      print('Error restoring wine: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
  }

  Future<void> updateCurrency(Currency currency) async {
    try {
      _setGridLoading(true);
      
      // Update local settings
      settings = settings.copyWith(currency: currency);
      
      // Save to Firestore
      await repository.saveGridSettings(settings);
      
      notifyListeners();
    } catch (e) {
      print('Error updating currency: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
    }
  }

  @override
  void dispose() {
    // Create new empty lists instead of clearing fixed-length lists
    _grid = [];
    drunkWines = [];
    _copiedWine = null;
    _loadingDebounceTimer?.cancel();
    super.dispose();
  }
}