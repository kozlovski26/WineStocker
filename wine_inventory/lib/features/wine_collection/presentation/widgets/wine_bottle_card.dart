import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/wine_bottle.dart';
import '../../utils/wine_type_helper.dart';

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
    // Wrap the card in an AspectRatio to maintain consistent dimensions.
    return FadeTransition(
      opacity: animation,
      child: AspectRatio(
        aspectRatio: 0.7, // Adjust card proportions as needed.
        child: Card(
          margin: const EdgeInsets.all(2), // Slightly reduced overall margin.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Container (70% of the card's height)
        Expanded(
          flex: 7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBottleImage(),
              if (bottle.isForTrade)
                Positioned(
                  top: 4, // Reduced top offset.
                  right: 4, // Reduced right offset.
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 2), // Reduced spacing.
                        Text(
                          'TRADE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Wine Information Section (30% of the card's height)
        Expanded(
          flex: 3,
          // Adjusted padding: less at the top, a bit more between wine name and year, and less at bottom.
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Center the contents vertically.
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Winery Row: placed with minimal top spacing.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (bottle.type != null)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: WineTypeHelper.getTypeColor(bottle.type!),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (bottle.winery != null) ...[
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          bottle.winery!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
                // Small gap between winery and wine name.
                const SizedBox(height: 2),
                // Adaptive wine name widget.
                AdaptiveWineName(
                  name: bottle.name ?? 'Unnamed Wine',
                  baseStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  containerHeight: 30,
                ),
                // Increased gap between wine name and year.
                const SizedBox(height: 4),
                // Wine Year with less space below.
                if (bottle.year != null)
                  Text(
                    bottle.year!,
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottleImage() {
    if (bottle.imagePath == null) {
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
        child: Icon(
          Icons.error_outline,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}

class AdaptiveWineName extends StatelessWidget {
  final String name;
  final TextStyle baseStyle;
  final double containerHeight;

  const AdaptiveWineName({
    Key? key,
    required this.name,
    required this.baseStyle,
    this.containerHeight = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final words = name.split(' ');
    String displayText;
    TextStyle effectiveStyle = baseStyle;

    if (words.length == 1) {
      // Single word - display as is with slightly larger font
      displayText = name;
      effectiveStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 11) + 2,
        height: 1.0,
      );
    } else if (words.length == 2) {
      // Two words - put them on separate lines
      displayText = words.join('\n');
      effectiveStyle = baseStyle.copyWith(height: 1.0);
    } else {
      // More than two words - keep on same line
      displayText = name;
      effectiveStyle = baseStyle.copyWith(height: 1.0);
    }

    return SizedBox(
      height: containerHeight,
      width: double.infinity,
      child: Center(
        child: Text(
          displayText,
          style: effectiveStyle,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl, // RTL for Hebrew
        ),
      ),
    );
  }
}
