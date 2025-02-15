import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/wine_bottle.dart';
import '../../utils/wine_type_helper.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wine_bar_outlined,
              size: 32,
              color: Colors.white24,
            ),
            SizedBox(height: 8),
            Text(
              'Add New Wine',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildBottleContent(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Expanded(
        flex: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBottleImage(),
            if (bottle.isForTrade)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            if (bottle.type != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: WineTypeHelper.getTypeColor(bottle.type!),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(1, 6, 1, 2),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bottle.winery != null)
              Text(
                bottle.winery!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  height: 1.0,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 3),
            Text(
              bottle.name ?? 'Unnamed Wine',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 11,
                height: 1,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            if (bottle.year != null && bottle.type != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  bottle.year!,
                  style: TextStyle(
                    color: WineTypeHelper.getTypeColor(bottle.type!),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
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
    return SizedBox(
      height: containerHeight,
      width: double.infinity,
      child: Center(
        child: Text(
          name,
          style: baseStyle.copyWith(height: 1.0),
          softWrap: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
