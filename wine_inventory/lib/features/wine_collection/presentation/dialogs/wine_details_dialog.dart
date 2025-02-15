import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wine_inventory/features/wine_collection/presentation/dialogs/wine_edit_dialog.dart';
import '../../domain/models/wine_bottle.dart';
import '../../utils/wine_type_helper.dart';
import '../managers/wine_manager.dart';
import 'package:intl/intl.dart';
import 'package:wine_inventory/features/wine_collection/presentation/widgets/wine_type_selector.dart';
import 'package:wine_inventory/features/wine_collection/presentation/widgets/wine_year_picker.dart';
import 'package:wine_inventory/features/wine_collection/presentation/screens/wine_photo_screen.dart';

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
  late TextEditingController nameController;
  late TextEditingController notesController;
  late TextEditingController priceController;
  late TextEditingController wineryController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bottle = widget.bottle.copyWith();
    nameController = TextEditingController(text: _bottle.name);
    wineryController = TextEditingController(text: _bottle.winery);
    notesController = TextEditingController(text: _bottle.notes);
    priceController = TextEditingController(
      text: _bottle.price?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    wineryController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildImageSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWineInfo(),
                            const SizedBox(height: 24),
                            _buildRatingAndFavorite(context),
                            _buildNotesSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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

  Widget _buildImageSection() {
    final typeColor = _bottle.type != null ? WineTypeHelper.getTypeColor(_bottle.type!) : Colors.red[400]!;
    
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              child: _bottle.imagePath != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WinePhotoScreen(),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'wine_image_${_bottle.imagePath}',
                        child: _bottle.imagePath!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: _bottle.imagePath!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _buildDefaultImage(),
                                errorWidget: (context, url, error) => _buildDefaultImage(),
                              )
                            : Image.file(
                                File(_bottle.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                              ),
                      ),
                    )
                  : _buildDefaultImage(),
            ),
            if (_isEditing)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _handleImageSelection,
                  backgroundColor: typeColor.withOpacity(0.9),
                  child: const Icon(Icons.camera_alt, size: 20),
                ),
              ),
          ],
        ),
        if (!_isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 16, bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _toggleEditMode,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor.withOpacity(0.9),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wine_bar,
              color: Colors.red[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Tap to add photo' : 'No photo available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWineInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          _isEditing
              ? TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Wine Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!),
                    ),
                  ),
                )
              : Text(
                  _bottle.name ?? '',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

          const SizedBox(height: 12),
          
          // Winery
          _isEditing
              ? TextField(
                  controller: wineryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Winery',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!),
                    ),
                  ),
                )
              : _buildWineryDisplay(),

          const SizedBox(height: 12),
          
          // Wine Type
          _buildTypeSelector(),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 16),

          // Additional Info
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildWineryDisplay() {
    if (_bottle.winery == null || _bottle.winery!.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.location_on, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _bottle.winery!,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Row(
      children: [
        // Year
        if (_bottle.year != null || _isEditing)
          Expanded(
            child: _isEditing
                ? WineYearPicker(
                    selectedYear: _bottle.year,
                    onYearSelected: (year) {
                      setState(() => _bottle.year = year);
                    },
                  )
                : _buildInfoColumn('YEAR', _bottle.year, Colors.red[300]!),
          ),

        // Price
        Expanded(
          child: _isEditing
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixText: '${widget.wineManager.settings.currency.symbol} ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red[400]!),
                      ),
                    ),
                  ),
                )
              : _buildInfoColumn(
                  'PRICE',
                  _bottle.price != null ? '${widget.wineManager.settings.currency.symbol}${_bottle.price!.toStringAsFixed(2)}' : null,
                  Colors.green[300]!,
                ),
        ),

        // Rating (always shown in display mode)
        if (!_isEditing && _bottle.rating != null)
          Expanded(
            child: _buildInfoColumn(
              'RATING',
              '${_bottle.rating!.toStringAsFixed(1)} ★',
              Colors.amber[300]!,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String? value, Color valueColor) {
    if (value == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    if (!_isEditing && (_bottle.notes == null || _bottle.notes!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
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
          _isEditing
              ? TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!),
                    ),
                  ),
                )
              : Text(
                  _bottle.notes ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isEditing) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _toggleEditMode,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.9),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[400],
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        // Reset controllers to original values
        nameController.text = _bottle.name ?? '';
        wineryController.text = _bottle.winery ?? '';
        notesController.text = _bottle.notes ?? '';
        priceController.text = _bottle.price?.toStringAsFixed(2) ?? '';
        _bottle = widget.bottle.copyWith();
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isLoading = true);

      // Parse price
      double? price;
      if (priceController.text.isNotEmpty) {
        price = double.tryParse(priceController.text.replaceAll(widget.wineManager.settings.currency.symbol, '').trim());
        if (price == null) throw Exception('Invalid price format');
      }

      // Update bottle with new values
      final updatedBottle = _bottle.copyWith(
        name: nameController.text,
        winery: wineryController.text,
        notes: notesController.text,
        price: price,
        imagePath: _bottle.imagePath,
        type: _bottle.type,
        year: _bottle.year,
      );

      // Save changes
      await widget.wineManager.updateWine(updatedBottle, widget.row, widget.col);
      
      if (mounted) {
        setState(() {
          _bottle = updatedBottle;
          _isEditing = false;
          _showSuccessMessage('Wine updated successfully');
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to save changes: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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

  Future<void> _handleImageSelection() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const WinePhotoScreen(),
      ),
    );

    if (imagePath != null) {
      setState(() {
        _bottle.imagePath = imagePath;
      });
    }
  }

  Widget _buildTypeSelector() {
    return _isEditing
        ? WineTypeSelector(
            selectedType: _bottle.type,
            onTypeSelected: (type) {
              setState(() => _bottle.type = type);
            },
          )
        : _buildTypeChip();
  }

  Widget _buildTypeChip() {
    if (_bottle.type == null) return const SizedBox.shrink();
    
    final typeColor = WineTypeHelper.getTypeColor(_bottle.type!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor),
      ),
      child: Text(
        _bottle.type!.name,
        style: TextStyle(
          color: typeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

