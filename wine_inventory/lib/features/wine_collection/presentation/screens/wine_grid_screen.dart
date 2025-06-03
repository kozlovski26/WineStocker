import 'package:flutter/material.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/core/models/currency.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import 'package:wine_inventory/features/wine_collection/data/repositories/wine_repository.dart';
import 'package:wine_inventory/features/wine_collection/domain/models/wine_bottle.dart';
import 'package:wine_inventory/features/wine_collection/presentation/dialogs/drunk_wines_dialog.dart';
import 'package:wine_inventory/features/wine_collection/presentation/screens/wine_photo_screen.dart';
import 'package:wine_inventory/features/wine_collection/presentation/screens/wine_scan_screen.dart';
import 'package:wine_inventory/features/wine_collection/services/gemini_service.dart';
import '../managers/wine_manager.dart';
import 'package:provider/provider.dart';
import '../widgets/wine_bottle_card.dart';
import '../widgets/wine_type_button.dart';
import '../dialogs/wine_details_dialog.dart';
import '../dialogs/wine_edit_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/share_dialog.dart';
import 'browse_users_screen.dart';
import 'package:wine_inventory/features/wine_collection/utils/wine_type_helper.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'dart:io';
import '../screens/wine_recognition_screen.dart';
import 'package:image_picker/image_picker.dart';

class WineGridScreen extends StatefulWidget {
  final String userId; // Add this line

  const WineGridScreen({
    super.key,
    required this.userId, // Add this line
  });

  @override
  WineGridScreenState createState() => WineGridScreenState();
}

class WineGridScreenState extends State<WineGridScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late WineRepository _repository; // Change this to late
  late WineManager _wineManager;
  bool _isPro = false;
  bool _canBrowseCollections = false;
  bool _isFabOpen = false;
  

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _repository = WineRepository(widget.userId); 
    _wineManager = WineManager(_repository);
    
    // Add this: Initialize with first-time setup check
    _initializeWineManager();
    
    _animationController.forward();
    _checkProStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkProStatus() async {
    final isPro = await _repository.isUserPro();
    final canBrowseCollections = await _repository.canBrowseAllCollections();
    print('DEBUG: _checkProStatus - isPro: $isPro, canBrowseCollections: $canBrowseCollections');
    if (mounted) {
      setState(() {
        _isPro = isPro;
        _canBrowseCollections = canBrowseCollections;
      });
      print('DEBUG: _checkProStatus - State updated - _isPro: $_isPro, _canBrowseCollections: $_canBrowseCollections');
    }
  }

  Future<void> _initializeWineManager() async {
    if (mounted) {
      final isFirstTime = await _wineManager.showFirstTimeSetup(context);
      if (!isFirstTime) {
        await _wineManager.loadData();
      }
    }
  }

  @override
    Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _wineManager,
      child: Consumer<WineManager>(
        builder: (context, wineManager, child) {
          if (!wineManager.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Stack(
            children: [
              Scaffold(
                appBar: _buildAppBar(context, wineManager),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBottleCount(wineManager),
                    _buildFilterButtons(wineManager),
                    _buildWineGrid(wineManager),
                  ],
                ),
              ),
              // Loading Overlay with fade animation
              if (wineManager.isGridLoading)
                AnimatedOpacity(
                  opacity: wineManager.isGridLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Card(
                        color: Colors.black87,
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Updating grid...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WineManager wineManager) {
    return AppBar(
      title: Text(
        'WINE FRIDGE',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.wine_bar),
          onPressed: () => _showDrunkWines(context, wineManager),
        ),
        _buildMoreMenu(context, wineManager),
      ],
    );
  }

  Widget _buildBottleCount(WineManager wineManager) {
    final totalValue = wineManager.grid
        .expand((row) => row)
        .where((bottle) => !bottle.isEmpty)
        .fold(0.0, (sum, bottle) => sum + (bottle.price ?? 0));

    final currencySymbol = wineManager.settings?.currency?.symbol ?? Currency.USD.symbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${wineManager.totalBottles} Bottles',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
          Text(
            '$currencySymbol${totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(WineManager wineManager) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildAllFilterButton(wineManager),
          const SizedBox(width: 8),
          ...WineType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WineTypeButton(
                type: type,
                isSelected: type == wineManager.selectedFilter,
                onTap: () => wineManager.setFilter(
                    type == wineManager.selectedFilter ? null : type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFilterButton(WineManager wineManager) {
    return GestureDetector(
      onTap: () => wineManager.setFilter(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: wineManager.selectedFilter == null
              ? Colors.red[400]?.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: wineManager.selectedFilter == null
                ? Colors.red[400]!
                : Colors.grey[700]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'All',
          style: TextStyle(
            color: wineManager.selectedFilter == null
                ? Colors.red[400]
                : Colors.grey[400],
            fontWeight: wineManager.selectedFilter == null
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWineGrid(WineManager wineManager) {
    return Expanded(
      child: _buildGridView(wineManager),
    );
  }

  Widget _buildGridView(WineManager wineManager) {
    // Check if there are any bottles matching the current filter
    bool hasMatchingBottles = false;
    if (wineManager.selectedFilter != null) {
      for (var row in wineManager.grid) {
        for (var bottle in row) {
          if (!bottle.isEmpty && bottle.type == wineManager.selectedFilter) {
            hasMatchingBottles = true;
            break;
          }
        }
        if (hasMatchingBottles) break;
      }
    }

    // If no matching bottles, show message
    if (wineManager.selectedFilter != null && !hasMatchingBottles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.liquor_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${WineTypeHelper.getTypeName(wineManager.selectedFilter!)} wines in your collection',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const maxVisibleColumns = 4;
    final settings = wineManager.settings;
    if (settings == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final columns = settings.columns;
    final cardWidth = columns <= maxVisibleColumns 
        ? screenWidth / columns 
        : screenWidth / maxVisibleColumns;
    final cardAspectRatio = settings.cardAspectRatio;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: columns <= maxVisibleColumns 
            ? screenWidth 
            : cardWidth * columns,
        child: GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: cardAspectRatio,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: settings.rows * columns,
          itemBuilder: (context, index) {
            final row = index ~/ columns;
            final col = index % columns;
            
            if (row >= wineManager.grid.length || 
                col >= wineManager.grid[row].length) {
              return const SizedBox.shrink();
            }

            final bottle = wineManager.grid[row][col];

            if (wineManager.selectedFilter != null && 
                (bottle.isEmpty || bottle.type != wineManager.selectedFilter)) {
              return Container(
                color: Colors.black12,
                child: Center(
                  child: Icon(
                    Icons.wine_bar_outlined,
                    color: Colors.grey[700],
                    size: 32,
                  ),
                ),
              );
            }

            return AnimatedOpacity(
              opacity: wineManager.isGridLoading ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: WineBottleCard(
                bottle: bottle,
                animation: _animation,
                onTap: () => bottle.isEmpty 
                  ? _showWineEditDialog(context, wineManager, row, col)
                  : _showWineDetailsDialog(context, wineManager, bottle, row, col),
                onLongPress: () => _handleBottleLongPress(
                  context, 
                  wineManager, 
                  bottle, 
                  row, 
                  col
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(WineManager wineManager) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: wineManager.settings.rows * wineManager.settings.columns,
      itemBuilder: (context, index) {
        final row = index ~/ wineManager.settings.columns;
        final col = index % wineManager.settings.columns;
        final bottle = wineManager.grid[row][col];

        if (bottle.isEmpty ||
            (wineManager.selectedFilter != null &&
                bottle.type != wineManager.selectedFilter)) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 250,
            child: WineBottleCard(
              bottle: bottle,
              animation: _animation,
              onTap: () => _showWineDetailsDialog(
                  context, wineManager, bottle, row, col),
              onLongPress: () => _showWineEditDialog(
                  context, wineManager, row, col,
                  isEdit: true),
            ),
          ),
        );
      },
    );
  }

  void _showWineDetailsDialog(
    BuildContext context,
    WineManager wineManager,
    WineBottle bottle,
    int row,
    int col,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => WineDetailsDialog(
        bottle: bottle,
        wineManager: wineManager,
        row: row,
        col: col,
        onDrinkWine: () {
          Navigator.pop(context); // Close details
          _showDrinkConfirmation(context, wineManager, bottle, row, col);
        },
      ),
    );
  }

  void _showWineEditDialog(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col, {
    bool isEdit = false,
  }) {
    if (isEdit) {
      // If editing existing wine, show the edit dialog directly
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) => WineEditDialog(
          bottle: wineManager.grid[row][col],
          wineManager: wineManager,
          row: row,
          col: col,
          isEdit: isEdit,
        ),
      );
    } else {
      // For new wine, start with photo capture
      _startWinePhotoCapture(context, wineManager, row, col);
    }
  }

  Future<void> _startWinePhotoCapture(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col,
  ) async {
    try {
      // Navigate to WinePhotoScreen to take or select a photo
      final photoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => WinePhotoScreen(isPro: _isPro)),
      );
      
      // If user canceled or something went wrong
      if (photoPath == null || !mounted) return;
      
      // Process the image
      final File imageFile = File(photoPath);
      
      // Check if user is Pro
      if (_isPro) {
        // Only Pro users get AI analysis
        // Show loading indicator for Pro users
        _showLoadingDialog(context, 'Analyzing wine image...');
        
        // Get the API key - using a constant for easier maintenance
        const String geminiApiKey = 'AIzaSyDjrSPjrVEjf5zuLfGlMHn3Ysda8lLz1kQ';
        
        // Create GeminiService and analyze image with appropriate model selection
        final geminiService = GeminiService(
          apiKey: geminiApiKey,
          modelName: 'gemini-2.0-flash', // Always use gemini-2.0-flash model
        );
        
        try {
          final analyzedWine = await geminiService.analyzeWineImage(imageFile);
          
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          if (analyzedWine == null) {
            // Analysis failed, show the empty edit dialog
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Could not fully analyze the wine label. Please fill in any missing details.',
                  ),
                  backgroundColor: Colors.orange[700],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
              
              _showEmptyWineEditDialog(context, wineManager, row, col, imageFile);
            }
          } else {
            // Analysis succeeded, show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Wine label analyzed successfully! Please verify and adjust details if needed.',
                  ),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            
            // Show edit dialog with pre-filled data
            _showWineEditDialogWithData(context, wineManager, row, col, analyzedWine, imageFile);
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          // Show error and continue with empty edit dialog
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error analyzing wine: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
            
            _showEmptyWineEditDialog(context, wineManager, row, col, imageFile);
          }
        }
      } else {
        // Non-Pro users skip AI analysis and go directly to manual entry
        _showEmptyWineEditDialog(context, wineManager, row, col, imageFile);
      }
    } catch (e) {
      // Handle any errors in photo capture process
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Our AI is examining the wine label to identify details such as name, winery, year, and type.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showEmptyWineEditDialog(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col,
    File imageFile,
  ) {
    if (!mounted) return;
    
    // Determine if this was initiated from the + button in the app bar
    final bool isFromAppBar = row == 0 && col == 0 && wineManager.grid[row][col].isEmpty;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => WineEditDialog(
        bottle: WineBottle(
          imagePath: imageFile.path, // Just set the image path
        ),
        wineManager: wineManager,
        row: row,
        col: col,
        isEdit: false,
        tempImageFile: imageFile,
        defaultSource: isFromAppBar ? WineSource.drinkList : WineSource.fridge,
      ),
    );
  }
  
  void _showWineEditDialogWithData(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col,
    WineBottle analyzedWine,
    File imageFile,
  ) {
    if (!mounted) return;
    
    // Determine if this was initiated from the + button in the app bar
    final bool isFromAppBar = row == 0 && col == 0 && wineManager.grid[row][col].isEmpty;
    
    // Update the analyzed wine with the image path
    final bottleToEdit = analyzedWine.copyWith(
      imagePath: imageFile.path,
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => WineEditDialog(
        bottle: bottleToEdit,
        wineManager: wineManager,
        row: row,
        col: col,
        isEdit: false,
        tempImageFile: imageFile,
        defaultSource: isFromAppBar ? WineSource.drinkList : WineSource.fridge,
      ),
    );
  }

  void _showDrunkWines(BuildContext context, WineManager wineManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DrunkWinesDialog(wineManager: wineManager),
    );
  }

  void _handleBottleLongPress(
  BuildContext context,
  WineManager wineManager,
  WineBottle bottle,
  int row,
  int col,
) {
  if (!bottle.isEmpty) {
    _showBottleOptionsMenu(context, wineManager, bottle, row, col);
  } else if (wineManager.hasCopiedWine) {
    _showEmptySlotOptionsMenu(context, wineManager, row, col);
  } else {
    _showWineEditDialog(context, wineManager, row, col);
  }
}

void _showBottleOptionsMenu(
  BuildContext context,
  WineManager wineManager,
  WineBottle bottle,
  int row,
  int col,
) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Wine'),
              onTap: () {
                Navigator.pop(context);
                _showWineEditDialog(context, wineManager, row, col, isEdit: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Wine'),
              onTap: () {
                wineManager.copyWine(bottle, row, col);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Wine copied. Long-press another slot to paste.'),
                    backgroundColor: Colors.green[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            if (wineManager.hasCopiedWine)
              ListTile(
                leading: const Icon(Icons.swap_horizontal_circle),
                title: const Text('Swap Wine'),
                onTap: () async {
                  Navigator.pop(context);
                  // Store the current bottle before pasting
                  final currentBottle = bottle.copyWith();
                  final currentRow = row;
                  final currentCol = col;
                  
                  // Paste the copied wine
                  await wineManager.pasteWine(row, col);
                  
                  // Now paste the previous bottle to the copied wine's original position
                  if (wineManager.copiedWinePosition != null) {
                    final originalPos = wineManager.copiedWinePosition!;
                    // Temporarily store the current bottle
                    wineManager.copyWine(currentBottle, currentRow, currentCol);
                    // Paste it to the original position
                    await wineManager.pasteWine(originalPos.row, originalPos.col);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Wine', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, wineManager, row, col);
              },
            ),
             ListTile(
              leading: const Icon(Icons.wine_bar, color: Colors.green),
              title: const Text('Drink Wine', style: TextStyle(color: Colors.green)),
              onTap: () {
                    Navigator.pop(context);
                _showDrinkConfirmation(
                      context, wineManager, bottle, row, col);
              },
            ),
          ],
        ),
      );
    },
  );
}

  void _showEmptySlotOptionsMenu(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col,
  ) {
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (wineManager.hasCopiedWine) ...[
                    ListTile(
                      leading: isProcessing 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.paste),
                      title: const Text('Paste Wine'),
                      enabled: !isProcessing,
                      onTap: () async {
                        setState(() => isProcessing = true);
                        try {
                          await wineManager.pasteWine(row, col);
                          await wineManager.clearCopiedWine(); // Clear copied wine after successful paste
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wine pasted successfully'),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error pasting wine: ${e.toString()}'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: isProcessing 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.swap_horizontal_circle),
                      title: const Text('Move Wine Here'),
                      subtitle: const Text('Move wine to this slot and clear original'),
                      enabled: !isProcessing,
                      onTap: () async {
                        setState(() => isProcessing = true);
                        try {
                          // Paste the copied wine to this empty slot
                          await wineManager.pasteWine(row, col);
                          
                          // If there was an original position, clear that slot
                          if (wineManager.copiedWinePosition != null) {
                            final originalPos = wineManager.copiedWinePosition!;
                            await wineManager.deleteWine(originalPos.row, originalPos.col);
                            await wineManager.clearCopiedWine(); // Clear copied wine after successful move
                          }
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wine moved successfully'),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error moving wine: ${e.toString()}'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add New Wine'),
                    enabled: !isProcessing,
                    onTap: () {
                      Navigator.pop(context);
                      _startWinePhotoCapture(context, wineManager, row, col);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

 void _showDrinkConfirmation(
    BuildContext context,
    WineManager wineManager,
    WineBottle bottle,
    int row,
    int col,
  ) {
    bool isProcessing = false;
    File? eventPhotoFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Drink Wine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mark this wine as drunk?'),
                  const SizedBox(height: 16),
                  if (eventPhotoFile != null)
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[600]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          eventPhotoFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: isProcessing ? null : () => _selectEventPhoto(context, (file) {
                      setState(() {
                        eventPhotoFile = file;
                      });
                    }),
                    icon: Icon(
                      eventPhotoFile != null ? Icons.edit : Icons.add_a_photo,
                      size: 20,
                    ),
                    label: Text(
                      eventPhotoFile != null ? 'Change Photo' : 'Add Event Photo',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setState(() => isProcessing = true);
                          try {
                            await wineManager.markAsDrunk(bottle, row, col, eventPhotoFile: eventPhotoFile);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Wine marked as drunk'),
                                  backgroundColor: Colors.green[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Drink'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectEventPhoto(BuildContext context, Function(File) onPhotoSelected) async {
    try {
      // Show a dialog to choose between camera and gallery
      final source = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      );
      
      if (source == null || !mounted) return;
      
      // Import image_picker within this method to avoid unnecessary dependencies
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        
        if (image != null) {
          onPhotoSelected(File(image.path));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

   void _showDeleteConfirmation(
    BuildContext context,
    WineManager wineManager,
    int row,
    int col,
  ) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Wine'),
              content: const Text('Are you sure you want to delete this wine?'),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setState(() => isProcessing = true);
                          try {
                            await wineManager.deleteWine(row, col);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Wine deleted'),
                                  backgroundColor: Colors.red[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoreMenu(BuildContext context, WineManager wineManager) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  repository: _repository,
                ),
              ),
            );
            break;
          case 'browse':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BrowseUsersScreen(),
              ),
            );
            break;
          case 'share':
            showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).cardColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => ShareDialog(wineManager: wineManager),
            );
            break;
          case 'settings':
            showDialog(
              context: context,
              builder: (context) => SettingsDialog(wineManager: wineManager),
            );
            break;
          case 'logout':
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[400],
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true && mounted) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            }
            break;
          case 'delete_account':
            _showDeleteAccountDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 20),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
        ),
        if (_canBrowseCollections)
          const PopupMenuItem<String>(
            value: 'browse',
            child: Row(
              children: [
                Icon(Icons.people, size: 20),
                SizedBox(width: 8),
                Text('Browse Collections'),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
     
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red[400]),
              const SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete_account',
          child: Row(
            children: [
              Icon(Icons.delete_forever, size: 20, color: Colors.red[400]),
              const SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmationController = TextEditingController();
    bool isProcessing = false;
    const confirmationPhrase = 'delete my account';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please type "delete my account" to confirm:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'delete my account',
                    ),
                    enabled: !isProcessing,
                    autocorrect: false,
                    onChanged: (value) => setState(() {}), // Trigger rebuild to update button state
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isProcessing || confirmationController.text != confirmationPhrase
                      ? null
                      : () async {
                          setState(() => isProcessing = true);
                          try {
                            final authProvider =
                                Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.deleteAccount();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/signin',
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToScanScreen(
    BuildContext context, 
    WineManager wineManager
  ) async {
    // Make sure we have the latest Pro status
    await _checkProStatus();
    
    try {
      // Navigate to WinePhotoScreen to take or select a photo
      final photoPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const WinePhotoScreen(isPro: true)),
      );
      
      // If user canceled or something went wrong
      if (photoPath == null || !mounted) return;
      
      // Process the image
      final File imageFile = File(photoPath);
      
      // Show loading indicator
      _showLoadingDialog(context, 'Analyzing wine image...');
      
      // Get the API key
      const String geminiApiKey = 'AIzaSyDjrSPjrVEjf5zuLfGlMHn3Ysda8lLz1kQ';
      
      // Create GeminiService and analyze image
      final geminiService = GeminiService(
        apiKey: geminiApiKey,
        modelName: 'gemini-2.0-flash',
      );
      
      try {
        // Analyze the wine image
        final analyzedWine = await geminiService.analyzeWineImage(imageFile);
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (analyzedWine == null) {
          // Analysis failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Could not analyze the wine label. Please try again.',
                ),
                backgroundColor: Colors.orange[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Analysis succeeded, show the WineRecognitionScreen with the results
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              builder: (context) => ChangeNotifierProvider.value(
                value: wineManager,
                child: WineRecognitionScreen(
                  initialImageFile: imageFile,
                  initialWine: analyzedWine,
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error analyzing wine: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors during photo capture
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showEditDialogWithImage(
    BuildContext context, 
    WineManager wineManager,
    WineBottle prefilledBottle,
    File? imageFile
  ) async {
    // Find an empty cell to add the wine
    int row = 0;
    int col = 0;
    bool foundEmptyCell = false;
    
    for (int i = 0; i < wineManager.grid.length; i++) {
      for (int j = 0; j < wineManager.grid[i].length; j++) {
        if (wineManager.grid[i][j].isEmpty) {
          row = i;
          col = j;
          foundEmptyCell = true;
          break;
        }
      }
      if (foundEmptyCell) break;
    }
    
    if (!foundEmptyCell) {
      // No empty cell found, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No empty cells available in your collection!')),
        );
      }
      return;
    }
    
    // If we have an image file, set a temporary path for display
    WineBottle bottleToEdit = prefilledBottle;
    if (imageFile != null) {
      bottleToEdit = bottleToEdit.copyWith(
        imagePath: imageFile.path,  // Temporary path for display
      );
    }
    
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => WineEditDialog(
          bottle: bottleToEdit,
          wineManager: wineManager,
          row: row,
          col: col,
          isEdit: false,
          // We'll pass the temp image file so it can be uploaded when saved
          tempImageFile: imageFile,
        ),
      );
    }
  }
  
  // Keep the original method for backward compatibility
  Future<void> _showEditDialog(
    BuildContext context, 
    WineManager wineManager,
    WineBottle prefilledBottle
  ) async {
    _showEditDialogWithImage(context, wineManager, prefilledBottle, null);
  }

  // New method to find an empty cell and start photo capture
  void _startAddNewWine(BuildContext context, WineManager wineManager) async {
    // Find first empty cell
    int row = 0;
    int col = 0;
    bool foundEmptyCell = false;
    
    for (int i = 0; i < wineManager.grid.length; i++) {
      for (int j = 0; j < wineManager.grid[i].length; j++) {
        if (wineManager.grid[i][j].isEmpty) {
          row = i;
          col = j;
          foundEmptyCell = true;
          break;
        }
      }
      if (foundEmptyCell) break;
    }
    
    if (!foundEmptyCell) {
      // No empty cell found, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No empty cells available in your collection!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Set row and col to 0 to indicate this is from the add button
    // This will be used in _showEmptyWineEditDialog to set the default source
    row = 0;
    col = 0;
    
    // Start photo capture for the found empty cell
    _startWinePhotoCapture(context, wineManager, row, col);
  }
}