import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wine_inventory/features/wine_collection/presentation/dialogs/wine_edit_dialog.dart';
import '../../domain/models/wine_bottle.dart';
import '../../utils/wine_type_helper.dart';
import '../managers/wine_manager.dart';

class WineDetailsDialog extends StatefulWidget {
  final WineBottle bottle;
  final WineManager wineManager;
  final int row;
  final int col;

  const WineDetailsDialog({
    super.key,
    required this.bottle,
    required this.wineManager,
    required this.row,
    required this.col,
  });

  @override
  State<WineDetailsDialog> createState() => _WineDetailsDialogState();
}

class _WineDetailsDialogState extends State<WineDetailsDialog> {
  late WineBottle _bottle;

  @override
  void initState() {
    super.initState();
    _bottle = WineBottle(
      name: widget.bottle.name,
      year: widget.bottle.year,
      notes: widget.bottle.notes,
      dateAdded: widget.bottle.dateAdded,
      dateDrunk: widget.bottle.dateDrunk,
      imagePath: widget.bottle.imagePath,
      type: widget.bottle.type,
      rating: widget.bottle.rating,
      isFavorite: widget.bottle.isFavorite,
      isDrunk: widget.bottle.isDrunk,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_bottle.imagePath != null) _buildImage(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeChip(),
                  const SizedBox(height: 16),
                  _buildWineInfo(),
                  const SizedBox(height: 24),
                  _buildRatingAndFavorite(context),
                  if (_bottle.notes != null && _bottle.notes!.isNotEmpty)
                    _buildNotes(),
                  const SizedBox(height: 32),
                  _buildEditButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (_bottle.imagePath == null) return const SizedBox.shrink();

    return Container(
      height: 400,
      width: double.infinity,
      child: Hero(
        tag: 'wine_image_${_bottle.imagePath}',
        child: _bottle.imagePath!.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: _bottle.imagePath!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => _buildImageError(),
              )
            : Image.file(
                File(_bottle.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImageError(),
              ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 400,
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    if (_bottle.type == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: WineTypeHelper.getTypeColor(_bottle.type!).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            WineTypeHelper.getTypeIcon(_bottle.type!),
            size: 16,
            color: WineTypeHelper.getTypeColor(_bottle.type!),
          ),
          const SizedBox(width: 4),
          Text(
            WineTypeHelper.getTypeName(_bottle.type!),
            style: TextStyle(
              color: WineTypeHelper.getTypeColor(_bottle.type!),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWineInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _bottle.name ?? '',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_bottle.year != null) ...[
          const SizedBox(height: 8),
          Text(
            _bottle.year!,
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingAndFavorite(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < (_bottle.rating ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
              onPressed: () => _updateRating(index + 1),
            );
          }),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _bottle.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _bottle.isFavorite ? Colors.red[400] : Colors.white70,
            size: 20,
          ),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Tasting Notes',
          style: TextStyle(
            color: Colors.red[300],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _bottle.notes!,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            builder: (context) => WineEditDialog(
              bottle: _bottle,
              wineManager: widget.wineManager,
              row: widget.row,
              col: widget.col,
              isEdit: true,
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Wine'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red[400],
          minimumSize: const Size(0, 56),
        ),
      ),
    );
  }

  Future<void> _updateRating(int rating) async {
    setState(() {
      if (_bottle.rating == rating) {
        _bottle.rating = null;
      } else {
        _bottle.rating = rating.toDouble();
      }
    });
    try {
      await widget.wineManager.updateWine(_bottle, widget.row, widget.col);
      if (mounted) {
        widget.bottle.rating = _bottle.rating;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update rating'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _bottle.isFavorite = !_bottle.isFavorite;
    });
    try {
      await widget.wineManager.updateWine(_bottle, widget.row, widget.col);
      if (mounted) {
        widget.bottle.isFavorite = _bottle.isFavorite;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update favorite status'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }
}