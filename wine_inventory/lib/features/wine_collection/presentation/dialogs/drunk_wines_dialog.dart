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
  // Add sort direction state
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final sortedDrunkWines = List<WineBottle>.from(widget.wineManager.drunkWines)
      ..sort((a, b) {
        if (_sortAscending) {
          return (a.dateDrunk ?? DateTime.now())
              .compareTo(b.dateDrunk ?? DateTime.now());
        } else {
          return (b.dateDrunk ?? DateTime.now())
              .compareTo(a.dateDrunk ?? DateTime.now());
        }
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: sortedDrunkWines.length,
                  itemBuilder: (context, index) {
                    final wine = sortedDrunkWines[index];
                    return Dismissible(
                      key: ObjectKey(wine),
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red[900]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
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
                      child: _buildWineCard(context, wine),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWineCard(BuildContext context, WineBottle wine) {
    // Get color based on wine type, defaulting to deep purple
    Color wineColor = Colors.deepPurple;
    if (wine.type != null) {
      wineColor = WineTypeHelper.getTypeColor(wine.type!);
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _showWineDetails(context, wine),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                wineColor.withOpacity(0.2),
                Colors.grey[900]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWineImageSection(wine),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWineInfoSection(wine, wineColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWineImageSection(WineBottle wine) {
    return Hero(
      tag: 'wine-image-${wine.hashCode}',
      child: Container(
        width: 85,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: wine.imagePath != null
              ? CachedNetworkImage(
                  imageUrl: wine.imagePath!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                  placeholder: (context, url) => _buildLoadingImage(),
                )
              : _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildWineInfoSection(WineBottle wine, Color wineColor) {
    String wineTypeName = 'Unknown';
    if (wine.type != null) {
      wineTypeName = WineTypeHelper.getTypeName(wine.type!);
    }
    
    String? priceString;
    if (wine.price != null) {
      priceString = wine.price!.toStringAsFixed(2);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (wine.type != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: wineColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: wineColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  wineTypeName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: wineColor.withOpacity(0.9),
                  ),
                ),
              ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wine_bar,
                    size: 14,
                    color: Colors.red[300],
                  ),
                  const SizedBox(width: 4),
                  if (wine.dateDrunk != null)
                    Text(
                      DateFormat.yMd().format(wine.dateDrunk!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          wine.name ?? 'Unnamed Wine',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (wine.winery != null) ...[
          const SizedBox(height: 4),
          Text(
            wine.winery!,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            if (wine.year != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wine.year!,
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            if (wine.year != null && wine.country != null)
              const SizedBox(width: 8),
            if (wine.country != null)
              Text(
                wine.country!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
            if (priceString != null) ...[
              const Spacer(),
              Text(
                priceString,
                style: TextStyle(
                  color: Colors.green[300],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[800]?.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add to Collection'),
                onPressed: () => _showGridSelectionDialog(context, wine),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.wine_bar_outlined,
                    size: 32,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Drunk Wines',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: _sortAscending 
                    ? 'Sort by newest first' 
                    : 'Sort by oldest first',
                  child: IconButton(
                    icon: Icon(
                      _sortAscending 
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Add date order indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.amber[300],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sortAscending ? 'Oldest first' : 'Newest first',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[800], thickness: 1, height: 1),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wine_bar_outlined,
                size: 80,
                color: Colors.red[300]?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No drunk wines yet',
              style: GoogleFonts.playfairDisplay(
                color: Colors.grey[300],
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Your wine drinking history will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Icon(
          Icons.wine_bar,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
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