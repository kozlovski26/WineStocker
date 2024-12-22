import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import 'package:wine_inventory/features/wine_collection/presentation/screens/wine_photo_screen.dart';
import 'package:wine_inventory/features/wine_collection/presentation/widgets/wine_type_selector.dart';
import '../../../../core/models/wine_type.dart';
import '../../domain/models/wine_bottle.dart';
import '../managers/wine_manager.dart';
import '../widgets/wine_year_picker.dart';

class WineEditDialog extends StatefulWidget {
  final WineBottle bottle;
  final WineManager wineManager;
  final int row;
  final int col;
  final bool isEdit;

  const WineEditDialog({
    super.key,
    required this.bottle,
    required this.wineManager,
    required this.row,
    required this.col,
    this.isEdit = false,
  });

  @override
  WineEditDialogState createState() => WineEditDialogState();
}

class WineEditDialogState extends State<WineEditDialog> {
  late TextEditingController nameController;
  late TextEditingController notesController;
  late TextEditingController priceController;
  late String? selectedYear;
  late WineType? selectedType;
  late bool hasPhoto;
  bool _isLoading = false;
  bool isForTrade = false;

  @override
  void initState() {
    super.initState();
    print(
        'Initial bottle isForTrade value: ${widget.bottle.isForTrade}'); // Debug log

    nameController = TextEditingController(text: widget.bottle.name);
    notesController = TextEditingController(text: widget.bottle.notes);
    priceController = TextEditingController(
      text: widget.bottle.price?.toStringAsFixed(2) ?? '',
    );
    selectedYear = widget.bottle.year;
    selectedType = widget.bottle.type;
    hasPhoto = widget.bottle.imagePath != null;

    // Explicitly set isForTrade from the bottle
    isForTrade = widget.bottle.isForTrade;

    print('Initialized isForTrade to: $isForTrade'); // Debug log
  }

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildNameField(),
                  const SizedBox(height: 24),
                  _buildWineTypeSelector(),
                  const SizedBox(height: 24),
                  _buildYearSelector(context),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 24),
                  _buildPriceField(),
                  const SizedBox(height: 24),
                  _buildTradeOption(),
                  const SizedBox(height: 24),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isEdit ? 'Edit Wine' : 'Add Wine',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
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
    );
  }

  Widget _buildWineTypeSelector() {
    return WineTypeSelector(
      selectedType: selectedType,
      onTypeSelected: (type) {
        setState(() {
          selectedType = type;
        });
      },
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    return WineYearPicker(
      selectedYear: selectedYear,
      onYearSelected: (year) {
        setState(() {
          selectedYear = year;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: notesController,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Tasting Notes',
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
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Price',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixText: '\$ ',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildTradeOption() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text(
          'Available for Trade',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Let others know this wine is available for trading',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        value: isForTrade,
        onChanged: (value) {
          print('Changing isForTrade to: $value'); // Debug log
          setState(() {
            isForTrade = value;
          });
        },
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        if (hasPhoto && widget.bottle.imagePath != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.bottle.imagePath!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.bottle.imagePath!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => _buildImageError(),
                    )
                  : Image.file(
                      File(widget.bottle.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImageError(),
                    ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleImageSelection,
            icon: Icon(
              hasPhoto ? Icons.check_circle : Icons.add_a_photo,
              size: 20,
              color: hasPhoto ? Colors.green : Colors.white,
            ),
            label: Text(
              hasPhoto ? 'Change Photo' : 'Add Photo',
              style: TextStyle(
                fontSize: 16,
                color: hasPhoto ? Colors.green : Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasPhoto ? Colors.green : Colors.red[400]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[900],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Error loading image',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _saveWine,
        icon: const Icon(Icons.save),
        label: const Text(
          'Save',
          style: TextStyle(fontSize: 18),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
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
        widget.bottle.imagePath = imagePath;
        hasPhoto = true;
      });

      if (mounted) {
        _showSuccessMessage();
      }
    }
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (widget.bottle.imagePath != null &&
        !widget.bottle.imagePath!.startsWith('http')) {
      try {
        return await widget.wineManager.repository
            .uploadWineImage(widget.bottle.imagePath!);
      } catch (e) {
        print('Error uploading image: $e');
        return null;
      }
    }
    return widget.bottle.imagePath;
  }

  Future<void> _saveWine() async {
  try {
    setState(() => _isLoading = true);
    final imageUrl = await _uploadImageIfNeeded();
    // Parse price
    double? price;
    if (priceController.text.isNotEmpty) {
      price = double.tryParse(priceController.text.replaceAll('\$', '').trim());
      if (price == null) {
        throw Exception('Invalid price format');
      }
    }

    final userId = context.read<AuthProvider>().user?.id;
    
    print('Saving wine with isForTrade: $isForTrade'); // Debug log
    
    widget.bottle.name = nameController.text;
    widget.bottle.year = selectedYear;
    widget.bottle.type = selectedType;
    widget.bottle.notes = notesController.text;
    widget.bottle.imagePath = imageUrl;
    widget.bottle.price = price;
    
    // Explicitly set isForTrade
    widget.bottle.isForTrade = isForTrade;
    
    widget.bottle.ownerId = userId;

    if (!widget.isEdit) {
      widget.bottle.dateAdded = DateTime.now();
    }

    await widget.wineManager.updateWine(widget.bottle, widget.row, widget.col);

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Failed to save wine: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showErrorSnackBar(String message) {
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

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Photo added successfully! All bottle photos will maintain the same proportions for consistency.'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
