import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';
import 'package:wine_inventory/core/models/wine_type.dart';  // Fixed import path
import '../dialogs/first_time_setup_dialog.dart';

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

  void toggleView() {
    isGridView = !isGridView;
    notifyListeners();
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

  Future<void> markAsDrunk(WineBottle bottle, int row, int col) async {
    try {
      _setGridLoading(true);

      drunkWines.add(bottle);
      _grid[row][col] = WineBottle();
      
      await Future.wait([
        repository.saveWineGrid(_grid),
        repository.saveDrunkWines(drunkWines)
      ]);
      
      _updateStatistics();

    } catch (e) {
      print('Error marking wine as drunk: $e');
      rethrow;
    } finally {
      _setGridLoading(false);
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