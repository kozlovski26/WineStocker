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
import '../widgets/country_selector.dart';

class WineEditDialog extends StatefulWidget {
  final WineBottle bottle;
  final WineManager wineManager;
  final int row;
  final int col;
  final bool isEdit;
  final File? tempImageFile;

  const WineEditDialog({
    super.key,
    required this.bottle,
    required this.wineManager,
    required this.row,
    required this.col,
    this.isEdit = false,
    this.tempImageFile,
  });

  @override
  WineEditDialogState createState() => WineEditDialogState();
}

class WineEditDialogState extends State<WineEditDialog> {
  late TextEditingController nameController;
  late TextEditingController notesController;
  late TextEditingController priceController;
  late TextEditingController wineryController;
  String? selectedCountry;
  late String? selectedYear;
  late WineType? selectedType;
  late bool hasPhoto;
  bool _isLoading = false;
  bool isForTrade = false;

  @override
  void initState() {
    super.initState();
    print('Initial winery value: ${widget.bottle.winery}'); 
    nameController = TextEditingController(text: widget.bottle.name);
    wineryController = TextEditingController(text: widget.bottle.winery);
    notesController = TextEditingController(text: widget.bottle.notes);
    priceController = TextEditingController(
      text: widget.bottle.price?.toStringAsFixed(2) ?? '',
    );
    selectedYear = widget.bottle.year;
    selectedType = widget.bottle.type;
    selectedCountry = widget.bottle.country;
    hasPhoto = widget.bottle.imagePath != null;
    isForTrade = widget.bottle.isForTrade;
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
    final topPadding = MediaQuery.of(context).padding.top + 40.0; // Increased padding for dynamic island

    return Stack(
      children: [
        Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topPadding), // Add space before header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildHeader(context),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormFields(),
                          const SizedBox(height: 16),
                          _buildNotesField(),
                          const SizedBox(height: 16),
                          _buildSaveButton(),
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
                        ],
                      ),
                    ),
                  ],
                ),
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
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.teal[600],
      decoration: InputDecoration(
        labelText: 'Wine Name',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildWineryField() {
    return TextField(
      controller: wineryController,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.teal[600],
      decoration: InputDecoration(
        labelText: 'Winery',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return CountrySelector(
      selectedCountry: selectedCountry,
      onCountrySelected: (country) {
        setState(() => selectedCountry = country);
      },
    );
  }

  Widget _buildWineTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: WineTypeSelector(
        selectedType: selectedType,
        onTypeSelected: (type) {
          setState(() {
            selectedType = type;
          });
        },
      ),
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
      cursorColor: Colors.teal[600],
      decoration: InputDecoration(
        labelText: 'Tasting Notes',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    final currency = widget.wineManager.settings.currency;
    return TextField(
      controller: priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.teal[600],
      decoration: InputDecoration(
        labelText: 'Price',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixText: '${currency.symbol} ',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
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
          print('Changing isForTrade to: $value');
          setState(() {
            isForTrade = value;
          });
        },
        activeColor: Colors.teal[400],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        if (hasPhoto && widget.bottle.imagePath != null)
          Center(
            child: Container(
              height: 300,
              width: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[600]!),
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
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleImageSelection,
            icon: Icon(
              hasPhoto ? Icons.check_circle : Icons.add_a_photo,
              size: 20,
              color: hasPhoto ? Colors.teal[600] : Colors.white,
            ),
            label: Text(
              hasPhoto ? 'Change Photo' : 'Add Photo',
              style: TextStyle(
                fontSize: 16,
                color: hasPhoto ? Colors.teal[600] : Colors.white,
                decoration: TextDecoration.none,
                decorationColor: Colors.teal[600],
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasPhoto ? Colors.teal[600]! : Colors.white24,
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
          backgroundColor: Colors.teal[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fieldWidth = (screenWidth - 48) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWineryField(),
        const SizedBox(height: 16),
        _buildNameField(),
        const SizedBox(height: 16),
        _buildCountrySelector(),
        const SizedBox(height: 16),
        if (!hasPhoto || (hasPhoto && widget.bottle.imagePath != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPhotoSection(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _buildYearSelector(context),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildPriceField(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          child: _buildWineTypeSelector(),
        ),
        const SizedBox(height: 16),
        _buildTradeOption(),
      ],
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
      
      // Parse price
      double? price;
      if (priceController.text.isNotEmpty) {
        // Remove any currency symbols and extra spaces before parsing
        final cleanedPrice = priceController.text
            .replaceAll(RegExp(r'[^\d.,]'), '') // Remove all non-numeric characters except . and ,
            .replaceAll(',', '.') // Replace comma with dot for decimal
            .trim();
            
        price = double.tryParse(cleanedPrice);
        if (price == null) {
          throw Exception('Invalid price format');
        }
      }

      final userId = context.read<AuthProvider>().user?.id;
      
      // Handle image upload if we have a temp file
      String? imagePath = widget.bottle.imagePath;
      if (widget.tempImageFile != null) {
        try {
          final imageUrl = await widget.wineManager.repository.uploadWineImage(widget.tempImageFile!.path);
          if (imageUrl != null) {
            imagePath = imageUrl;
          }
        } catch (e) {
          print('Error uploading image: $e');
          // Continue with save even if image upload fails
        }
      }

      // Create updated bottle with all the new values
      final updatedBottle = WineBottle(
        name: nameController.text,
        winery: wineryController.text,
        year: selectedYear,
        notes: notesController.text,
        imagePath: imagePath,
        type: selectedType,
        rating: widget.bottle.rating,
        price: price,
        isFavorite: widget.bottle.isFavorite,
        isForTrade: isForTrade,
        ownerId: userId,
        dateAdded: widget.isEdit ? widget.bottle.dateAdded : DateTime.now(),
        country: selectedCountry,
      );

      // Update the wine in the manager
      await widget.wineManager.updateWine(updatedBottle, widget.row, widget.col);
      
      // Update the grid immediately with the new values
      widget.wineManager.grid[widget.row][widget.col] = updatedBottle;
      widget.wineManager.notifyListeners(); // Force UI update
      
      // Then refresh from database to ensure consistency
      await widget.wineManager.loadData();
      
      if (mounted) {
        Navigator.pop(context, updatedBottle);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wine updated successfully'),
            backgroundColor: Colors.teal[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save wine: ${e.toString()}'),
            backgroundColor: Colors.teal[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
        backgroundColor: Colors.teal[700],
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
        backgroundColor: Colors.teal[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
