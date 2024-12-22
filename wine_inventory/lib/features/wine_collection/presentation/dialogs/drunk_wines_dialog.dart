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
      builder: (context, scrollController) => Column(
        children: [
          _buildHeader(),
          if (sortedDrunkWines.isEmpty)
            _buildEmptyState()
          else
            _buildDrunkWinesList(sortedDrunkWines, scrollController),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Drunk Wines',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Expanded(
      child: Center(
        child: Text(
          'No drunk wines yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDrunkWinesList(
      List<WineBottle> sortedDrunkWines, ScrollController scrollController) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: sortedDrunkWines.length,
        itemBuilder: (context, index) {
          final wine = sortedDrunkWines[index];
          return Dismissible(
            key: ObjectKey(wine),
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
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
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: _buildWineImage(wine.imagePath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wine.name ?? 'Unnamed Wine',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (wine.year != null) ...[
                        Text(
                          wine.year!,
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Drunk on: ${DateFormat('MMMM d, y').format(wine.dateDrunk!)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: WineTypeHelper.getTypeColor(wine.type!)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wine_bar,
                                  size: 16,
                                  color: WineTypeHelper.getTypeColor(wine.type!),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  WineTypeHelper.getTypeName(wine.type!),
                                  style: TextStyle(
                                    color: WineTypeHelper.getTypeColor(wine.type!),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (wine.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber[400], size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  wine.rating!.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.wine_bar,
            color: Colors.white24,
            size: 32,
          ),
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(),
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
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white24,
          size: 32,
        ),
      ),
    );
  }

  void _handleDismiss(BuildContext context, WineBottle wine) {
    wineManager.removeDrunkWine(wine);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Wine removed from history'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Undo',
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