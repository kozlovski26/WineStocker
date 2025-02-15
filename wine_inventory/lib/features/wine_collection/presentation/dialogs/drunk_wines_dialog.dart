import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/wine_bottle.dart';
import '../managers/wine_manager.dart';
import '../../utils/wine_type_helper.dart';
import './wine_details_dialog.dart';
import '../../../../core/models/currency.dart';

class DrunkWinesDialog extends StatefulWidget {
  final WineManager wineManager;

  const DrunkWinesDialog({
    super.key,
    required this.wineManager,
  });

  @override
  State<DrunkWinesDialog> createState() => _DrunkWinesDialogState();
}

class _DrunkWinesDialogState extends State<DrunkWinesDialog> {
  @override
  Widget build(BuildContext context) {
    final sortedDrunkWines = List<WineBottle>.from(widget.wineManager.drunkWines)
      ..sort((a, b) => (b.dateDrunk ?? DateTime.now())
          .compareTo(a.dateDrunk ?? DateTime.now()));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (sortedDrunkWines.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedDrunkWines.length,
                  itemBuilder: (context, index) {
                    final wine = sortedDrunkWines[index];
                    return Dismissible(
                      key: ObjectKey(wine),
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[900]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => _handleDismiss(context, wine),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _showWineDetails(context, wine),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (wine.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: wine.imagePath!,
                                      width: 80,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wine.name ?? 'Unnamed Wine',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (wine.winery != null) ...[
                                        Text(
                                          wine.winery!,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (wine.year != null) ...[
                                        Text(
                                          wine.year!,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (wine.dateDrunk != null)
                                        Text(
                                          DateFormat('MMMM d, y').format(wine.dateDrunk!),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Tooltip(
                                  message: 'Add another bottle to collection',
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.green[700]?.withOpacity(0.2),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Got Another'),
                                    onPressed: () => _showGridSelectionDialog(context, wine),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.wine_bar_outlined,
                  size: 32,
                  color: Colors.red[400],
                ),
                const SizedBox(width: 16),
                Text(
                  'Drunk Wines',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[800], thickness: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wine_bar_outlined,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 24),
            Text(
              'No drunk wines yet',
              style: GoogleFonts.playfairDisplay(
                color: Colors.grey[500],
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your wine drinking history will appear here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWineImage(String imagePath) {
    return CachedNetworkImage(
      imageUrl: imagePath,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[800],
        child: Icon(
          Icons.wine_bar,
          size: 80,
          color: Colors.grey[600],
        ),
      ),
      placeholder: (context, url) => Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _showWineDetails(BuildContext context, WineBottle wine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WineDetailsDialog(
        bottle: wine,
        wineManager: widget.wineManager,
        row: -1,
        col: -1,
        isDrunkWine: true,
      ),
    );
  }

  void _handleDismiss(BuildContext context, WineBottle wine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isProcessing = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Delete from History',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to remove this wine from your drinking history?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing 
                    ? null 
                    : () {
                        Navigator.pop(context);
                        // Rebuild the list to restore the item
                        this.setState(() {});
                      },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: isProcessing
                    ? null
                    : () async {
                        setState(() => isProcessing = true);
                        try {
                          await widget.wineManager.removeDrunkWine(wine);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wine removed from history'),
                                backgroundColor: Colors.red[900],
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                backgroundColor: Colors.red[900],
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showGridSelectionDialog(BuildContext context, WineBottle wine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Grid Position',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap an empty slot (green) to add this wine to your collection',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.wineManager.settings.rows,
                          (row) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.wineManager.settings.columns,
                              (col) {
                                final currentBottle = widget.wineManager.grid[row][col];
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: currentBottle.isEmpty 
                                      ? () => _restoreToPosition(context, wine, row, col)
                                      : null,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: currentBottle.isEmpty 
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                        border: Border.all(
                                          color: currentBottle.isEmpty 
                                            ? Colors.green.withOpacity(0.5)
                                            : Colors.red.withOpacity(0.5),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        currentBottle.isEmpty 
                                          ? Icons.add
                                          : Icons.wine_bar,
                                        color: currentBottle.isEmpty 
                                          ? Colors.green[400]
                                          : Colors.red[400],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restoreToPosition(
    BuildContext context,
    WineBottle wine,
    int row,
    int col,
  ) async {
    try {
      // Create restored wine
      final restoredWine = wine.copyWith(
        isDrunk: false,
        dateDrunk: null,
        dateAdded: DateTime.now(),
      );

      // Update grid
      await widget.wineManager.updateWine(restoredWine, row, col);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${wine.name} copied to collection'),
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
            content: Text('Error restoring wine: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}