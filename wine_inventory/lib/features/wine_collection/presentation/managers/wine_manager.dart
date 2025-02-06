import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/wine_collection/presentation/dialogs/first_time_setup_dialog.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';

class WineManager extends ChangeNotifier {
  final WineRepository repository;
  List<List<WineBottle>> _grid;  // Initialize in constructor
  List<WineBottle> drunkWines = [];
  late GridSettings settings;  // Initialize in constructor
  WineType? _selectedFilter;
  int totalBottles = 0;
  double totalCollectionValue = 0.0;
  bool isGridView = true;
  bool _isLoading = false;
  bool _isInitialized = false;
  WineBottle? _copiedWine;

  WineManager(this.repository) : 
    _grid = [],
    settings = GridSettings.defaultSettings() {
    loadData();
  }

  // Getters
  List<List<WineBottle>> get grid => _grid;
  bool get isInitialized => _isInitialized; 
  bool get isLoading => _isLoading;
  bool get hasCopiedWine => _copiedWine != null;
  WineType? get selectedFilter => _selectedFilter;
  WineBottle? get copiedWine => _copiedWine;

  void _initializeGrid() {
    _grid = List.generate(
      settings.rows,
      (i) => List.generate(
        settings.columns,
        (j) => WineBottle(),
      ),
    );
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

  Future<void> loadData() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      _isInitialized = false;  // Reset initialized state
      notifyListeners();

      // Load settings first
      settings = await repository.loadGridSettings();
      
      // Initialize grid with current settings
      _grid = List.generate(
        settings.rows,
        (i) => List.generate(
          settings.columns,
          (j) => WineBottle(),
        ),
      );

      // Load existing data
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
      _grid = List.generate(
        settings.rows,
        (i) => List.generate(
          settings.columns,
          (j) => WineBottle(),
        ),
      );
    } finally {
      _isLoading = false;
      _isInitialized = true;  // Mark as initialized
      notifyListeners();
    }
  }

  bool _isValidPosition(int row, int col) {
    return _grid.isNotEmpty && 
           row >= 0 && 
           col >= 0 && 
           row < _grid.length && 
           _grid[row].isNotEmpty &&
           col < _grid[row].length;
  }

  void toggleView() {
    isGridView = !isGridView;
    notifyListeners();
  }

  void setFilter(WineType? type) {
    _selectedFilter = (_selectedFilter == type) ? null : type;
    _updateStatistics();
    notifyListeners();
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

  Future<void> copyWine(WineBottle bottle) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String? newImagePath = bottle.imagePath;
      if (bottle.imagePath != null && bottle.imagePath!.startsWith('http')) {
        newImagePath = await repository.copyWineImage(bottle.imagePath!);
      }
      
      _copiedWine = WineBottle(
        name: bottle.name,
        year: bottle.year,
        notes: bottle.notes,
        type: bottle.type,
        rating: bottle.rating,
        isFavorite: bottle.isFavorite,
        imagePath: newImagePath,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWine(WineBottle bottle, int row, int col) async {
    if (!_isValidPosition(row, col)) return;
    
    _grid[row][col] = bottle;
    await saveData();
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
    
    // Save wine grid
    await repository.saveWineGrid(_grid);
    
    // Save drunk wines
    await repository.saveDrunkWines(drunkWines);
    
    // Update statistics
    _updateStatistics();
  } catch (e) {
    print('Error in saveData: $e');
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
    
    // Create a copy of the bottle to be marked as drunk
    final drunkBottle = WineBottle(
      name: bottle.name,
      year: bottle.year,
      notes: bottle.notes,
      type: bottle.type,
      imagePath: bottle.imagePath,
      rating: bottle.rating,
      price: bottle.price,
      dateAdded: bottle.dateAdded,
      // Set drunk-specific properties
      isDrunk: true,
      dateDrunk: DateTime.now(),
      isFavorite: bottle.isFavorite,
      isForTrade: bottle.isForTrade,
      ownerId: bottle.ownerId
    );

    // Add to drunk wines list
    drunkWines.add(drunkBottle);

    // Remove from grid
    _grid[row][col] = WineBottle();

    // Save changes to Firestore
    await saveData();

  } catch (e) {
    print('Error marking wine as drunk: $e');
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
      notifyListeners();

    } catch (e) {
      print('Error deleting wine: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBottleWithImage(WineBottle bottle, int row, int col, String localPath) async {
    if (!_isValidPosition(row, col)) return;

    try {
      _isLoading = true;
      notifyListeners();

      if (bottle.imagePath != null && bottle.imagePath!.startsWith('http')) {
        await repository.deleteWineImage(bottle.imagePath!);
      }

      final imageUrl = await repository.uploadWineImage(localPath);
      if (imageUrl != null) {
        bottle.imagePath = imageUrl;
        await updateWine(bottle, row, col);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pasteWine(int row, int col) async {
  if (!_isValidPosition(row, col) || _copiedWine == null) return;

  try {
    // Ensure loading state is managed
    _isLoading = true;
    notifyListeners();

    // Handle image copying
    String? newImageUrl;
    if (_copiedWine!.imagePath != null && _copiedWine!.imagePath!.startsWith('http')) {
      newImageUrl = await repository.copyWineImage(_copiedWine!.imagePath!);
    }

    // Create a new WineBottle with copied details
    final pastedWine = WineBottle(
      name: _copiedWine!.name,
      year: _copiedWine!.year,
      notes: _copiedWine!.notes,
      type: _copiedWine!.type,
      rating: _copiedWine!.rating,
      isFavorite: _copiedWine!.isFavorite,
      imagePath: newImageUrl ?? _copiedWine!.imagePath,
      dateAdded: DateTime.now(),
      isForTrade: _copiedWine!.isForTrade,
      price: _copiedWine!.price,
    );

    // Update the grid and save to Firestore
    _grid[row][col] = pastedWine;
    await saveData();
  } catch (e) {
    print('Error pasting wine: $e');
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

  @override
  void dispose() {
    _grid.clear();
    drunkWines.clear();
    _copiedWine = null;
    super.dispose();
  }
}

extension WineManagerReorder on WineManager {
  Future<void> reorderWines(int fromRow, int fromCol, int toRow, int toCol) async {
    if (!_isValidPosition(fromRow, fromCol) || !_isValidPosition(toRow, toCol)) {
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Store the wines
      final sourceWine = _grid[fromRow][fromCol];
      final targetWine = _grid[toRow][toCol];

      // Swap the wines
      _grid[fromRow][fromCol] = targetWine;
      _grid[toRow][toCol] = sourceWine;

      // Save changes to Firestore
      await saveData();
      
    } catch (e) {
      print('Error reordering wines: $e');
      // Revert changes if save fails
      final sourceWine = _grid[toRow][toCol];
      final targetWine = _grid[fromRow][fromCol];
      _grid[toRow][toCol] = targetWine;
      _grid[fromRow][fromCol] = sourceWine;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}