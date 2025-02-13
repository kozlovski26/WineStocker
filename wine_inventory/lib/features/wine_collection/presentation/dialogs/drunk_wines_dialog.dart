import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/wine_bottle.dart';
import '../managers/wine_manager.dart';
import '../../utils/wine_type_helper.dart';

class DrunkWinesDialog extends StatelessWidget {
  final WineManager wineManager;

  const DrunkWinesDialog({
    super.key,
    required this.wineManager,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDrunkWines = List<WineBottle>.from(wineManager.drunkWines)
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
              _buildDrunkWinesList(sortedDrunkWines, scrollController),
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

  Widget _buildDrunkWinesList(
      List<WineBottle> sortedDrunkWines, ScrollController scrollController) {
    return Expanded(
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
            child: _buildDrunkWineCard(wine),
          );
        },
      ),
    );
  }

  Widget _buildDrunkWineCard(WineBottle wine) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: _buildWineImage(wine.imagePath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 8),
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
                      Text(
                        'Drunk on: ${DateFormat('MMMM d, y').format(wine.dateDrunk!)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: WineTypeHelper.getTypeColor(wine.type!)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: WineTypeHelper.getTypeColor(wine.type!)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wine_bar,
                                  size: 16,
                                  color: WineTypeHelper.getTypeColor(wine.type!),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  WineTypeHelper.getTypeName(wine.type!),
                                  style: TextStyle(
                                    color: WineTypeHelper.getTypeColor(wine.type!),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (wine.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[900]?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber[600]!.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    wine.rating!.toString(),
                                    style: TextStyle(
                                      color: Colors.amber[500],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWineImage(String? imagePath) {
    if (imagePath == null) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            Icons.wine_bar_rounded,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildImageError(),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }

  void _handleDismiss(BuildContext context, WineBottle wine) {
    wineManager.removeDrunkWine(wine);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Wine removed from history'),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            wineManager.drunkWines.add(wine);
            wineManager.drunkWines.sort((a, b) =>
                (b.dateDrunk ?? DateTime.now())
                    .compareTo(a.dateDrunk ?? DateTime.now()));
            await wineManager.saveData();
          },
        ),
      ),
    );
  }
}