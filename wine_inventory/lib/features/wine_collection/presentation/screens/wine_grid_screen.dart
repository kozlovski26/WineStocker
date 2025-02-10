import 'package:flutter/material.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import 'package:wine_inventory/features/wine_collection/data/repositories/wine_repository.dart';
import 'package:wine_inventory/features/wine_collection/domain/models/wine_bottle.dart';
import 'package:wine_inventory/features/wine_collection/presentation/dialogs/drunk_wines_dialog.dart';
import '../managers/wine_manager.dart';
import 'package:provider/provider.dart';
import '../widgets/wine_bottle_card.dart';
import '../widgets/wine_type_button.dart';
import '../dialogs/wine_details_dialog.dart';
import '../dialogs/wine_edit_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/share_dialog.dart';
import 'browse_users_screen.dart';
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
    _wineManager.loadData();
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
    if (mounted) {
      setState(() {
        _isPro = isPro;
      });
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
          
          return Scaffold(
            appBar: _buildAppBar(context, wineManager),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBottleCount(wineManager),
                _buildFilterButtons(wineManager),
                _buildWineGrid(wineManager),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WineManager wineManager) {
    return AppBar(
      title: Text(
        'MY WINES',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.wine_bar),
          onPressed: () => _showDrunkWines(context, wineManager),
        ),
        IconButton(
          icon: Icon(
            wineManager.isGridView ? Icons.view_list : Icons.grid_view,
          ),
          onPressed: () {
            _animationController.reset();
            wineManager.toggleView();
            _animationController.forward();
          },
        ),
        _buildMoreMenu(context, wineManager),
      ],
    );
  }

  Widget _buildBottleCount(WineManager wineManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      child: Text(
        '${wineManager.totalBottles} Bottels',
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white70,
        ),
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
      child: wineManager.isGridView
          ? _buildGridView(wineManager)
          : _buildListView(wineManager),
    );
  }

Widget _buildGridView(WineManager wineManager) {
  final screenWidth = MediaQuery.of(context).size.width;
  const maxVisibleColumns = 4;
  final cardWidth = wineManager.settings.columns <= maxVisibleColumns 
      ? screenWidth / wineManager.settings.columns 
      : screenWidth / maxVisibleColumns;
  const cardAspectRatio = 0.35;
  
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: wineManager.settings.columns <= maxVisibleColumns 
          ? screenWidth 
          : cardWidth * wineManager.settings.columns,
      child: GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: wineManager.settings.columns,
          childAspectRatio: cardAspectRatio,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: wineManager.settings.rows * wineManager.settings.columns,
        itemBuilder: (context, index) {
          final row = index ~/ wineManager.settings.columns;
          final col = index % wineManager.settings.columns;
          final bottle = wineManager.grid[row][col];

          if (wineManager.selectedFilter != null && 
              !bottle.isEmpty && 
              bottle.type != wineManager.selectedFilter) {
            return const SizedBox.shrink();
          }

          return WineBottleCard(
            bottle: bottle,
            animation: _animation,
            onTap: () => bottle.isEmpty 
              ? _showWineEditDialog(context, wineManager, row, col)
              : _showWineDetailsDialog(context, wineManager, bottle, row, col),
            onLongPress: () => _handleBottleLongPress(context, wineManager, bottle, row, col),
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
                leading: const Icon(Icons.paste),
                title: const Text('Replace Wine'),
                onTap: () async {
                  Navigator.pop(context);
                 await wineManager.pasteWine(row, col);
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
                  if (wineManager.hasCopiedWine)
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
                    leading: const Icon(Icons.add),
                    title: const Text('Add New Wine'),
                    enabled: !isProcessing,
                    onTap: () {
                      Navigator.pop(context);
                      _showWineEditDialog(context, wineManager, row, col);
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Drink Wine'),
              content: const Text('Mark this wine as drunk?'),
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
                            await wineManager.markAsDrunk(bottle, row, col);
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
        }
      },
      itemBuilder: (BuildContext context) => [
        if (_isPro)
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
      ],
    );
  }
}