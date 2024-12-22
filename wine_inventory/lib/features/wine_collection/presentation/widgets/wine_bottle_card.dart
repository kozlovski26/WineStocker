import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/wine_bottle.dart';
import '../../utils/wine_type_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WineBottleCard extends StatelessWidget {
  final WineBottle bottle;
  final Animation<double> animation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WineBottleCard({
    super.key,
    required this.bottle,
    required this.animation,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Card(
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: bottle.isEmpty
              ? _buildEmptyBottle()
              : _buildBottleContent(context),
        ),
      ),
    );
  }

  Widget _buildEmptyBottle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[800]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          size: 32,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildBottleContent(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBottleImage(),
        _buildBottleOverlay(),
        _buildBottleInfo(context),
        if (bottle.type != null) _buildTypeIndicator(),
        if (bottle.isFavorite) _buildFavoriteIndicator(),
        if (bottle.isForTrade)
  Positioned(
    top: 8,
    right: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.swap_horiz,
        color: Colors.green,
        size: 16,
      ),
    ),
  ),
      ],
    );
  }

  Widget _buildBottleImage() {
    if (bottle.imagePath == null) {
      return Container(color: Colors.grey[900]);
    }

    if (bottle.imagePath!.startsWith('http')) {
      return Hero(
        tag: 'wine_image_${bottle.imagePath}',
        child: CachedNetworkImage(
          imageUrl: bottle.imagePath!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildImageError(),
        ),
      );
    } else {
      return Hero(
        tag: 'wine_image_${bottle.imagePath}',
        child: Image.file(
          File(bottle.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImageError(),
        ),
      );
    }
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.white54, size: 32),
      ),
    );
  }

  Widget _buildBottleOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.5, 0.9],
        ),
      ),
    );
  }

  Widget _buildTypeIndicator() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: WineTypeHelper.getTypeColor(bottle.type!).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          // Added ConstrainedBox
          constraints:
              const BoxConstraints(maxWidth: 120), // Limit maximum width
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                WineTypeHelper.getTypeIcon(bottle.type!),
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              // Flexible(
              //   // Added Flexible
              //   child: Text(
              //     WineTypeHelper.getTypeName(bottle.type!),
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 12,
              //       fontWeight: FontWeight.bold,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteIndicator() {
    return const Positioned(
      top: 8,
      right: 8,
      child: Icon(
        Icons.favorite,
        color: Colors.red,
        size: 20,
      ),
    );
  }

  // In WineBottleCard class, update _buildBottleInfo:

  Widget _buildBottleInfo(BuildContext context) {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottle.name != null)
            Text(
              bottle.name!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min, // Changed to min
            children: [
              if (bottle.year != null)
                Flexible(
                  // Added Flexible
                  child: Text(
                    bottle.year!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (bottle.year != null && bottle.rating != null)
                const SizedBox(width: 8),
              if (bottle.rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bottle.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              // if (bottle.price != null) ...[
              //   const SizedBox(height: 4),
              //   Text(
              //     '\$${bottle.price!.toStringAsFixed(2)}',
              //     style: TextStyle(
              //       color: Colors.green[400],
              //       fontSize: 14,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ],
            ],
          ),
        ],
      ),
    );
  }
}
