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
import 'package:image_picker/image_picker.dart';

class WineEditDialog extends StatefulWidget {
  final WineBottle bottle;
  final WineManager wineManager;
  final int row;
  final int col;
  final bool isEdit;
  final File? tempImageFile;
  final WineSource? defaultSource;

  const WineEditDialog({
    super.key,
    required this.bottle,
    required this.wineManager,
    required this.row,
    required this.col,
    this.isEdit = false,
    this.tempImageFile,
    this.defaultSource,
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
  late WineSource wineSource;
  File? eventPhotoFile;

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
    wineSource = widget.defaultSource ?? widget.bottle.source;
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

  Widget _buildSourceSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Radio<WineSource>(
                  value: WineSource.fridge,
                  groupValue: wineSource,
                  onChanged: (WineSource? value) {
                    if (value != null) {
                      setState(() => wineSource = value);
                    }
                  },
                  activeColor: Colors.teal[400],
                ),
              ),
              Flexible(
                child: Text(
                  'In Fridge',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 24.0),
              SizedBox(
                width: 40,
                child: Radio<WineSource>(
                  value: WineSource.drinkList,
                  groupValue: wineSource,
                  onChanged: (WineSource? value) {
                    if (value != null) {
                      setState(() => wineSource = value);
                    }
                  },
                  activeColor: Colors.teal[400],
                ),
              ),
              Flexible(
                child: Text(
                  'Drink List',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (wineSource == WineSource.drinkList) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Event Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a photo from the moment you enjoyed this wine',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 12),
            if (eventPhotoFile != null)
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[600]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    eventPhotoFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _selectEventPhoto,
                icon: Icon(
                  eventPhotoFile != null ? Icons.edit : Icons.add_a_photo,
                  size: 20,
                  color: Colors.amber[400],
                ),
                label: Text(
                  eventPhotoFile != null ? 'Change Event Photo' : 'Add Event Photo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber[400],
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amber[600]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
        _buildSourceSelector(),
        const SizedBox(height: 16),
        _buildTradeOption(),
      ],
    );
  }

  Future<void> _handleImageSelection() async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const WinePhotoScreen(isPro: false),
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
        source: wineSource,
      );
      
      // Check if wine is from external source
      if (wineSource == WineSource.drinkList) {
        // For external wines, add directly to drunk list instead of fridge
        final drunkWine = updatedBottle.copyWith(
          isDrunk: true,
          dateDrunk: DateTime.now(),
        );
        
        // Add to drunk wines collection
        await widget.wineManager.addDrunkWine(drunkWine, imageFile: widget.tempImageFile, eventPhotoFile: eventPhotoFile);
        
        if (mounted) {
          Navigator.pop(context, drunkWine);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Wine added to your drinking history'),
              backgroundColor: Colors.amber[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // For wines saved to the fridge, we need to ensure we're not overriding an existing wine
        if (widget.isEdit) {
          // For edits, update at the existing position
          await widget.wineManager.updateWine(updatedBottle, widget.row, widget.col);
          
          // Update the grid immediately with the new values
          widget.wineManager.grid[widget.row][widget.col] = updatedBottle;
          widget.wineManager.notifyListeners(); // Force UI update
        } else {
          // For new wines, find an empty slot
          int row = widget.row;
          int col = widget.col;
          bool foundEmptySlot = false;
          
          // First check if the provided position is empty
          if (widget.wineManager.grid[row][col].isEmpty) {
            foundEmptySlot = true;
          } else {
            // Search for an empty slot
            for (int i = 0; i < widget.wineManager.grid.length; i++) {
              for (int j = 0; j < widget.wineManager.grid[i].length; j++) {
                if (widget.wineManager.grid[i][j].isEmpty) {
                  row = i;
                  col = j;
                  foundEmptySlot = true;
                  break;
                }
              }
              if (foundEmptySlot) break;
            }
          }
          
          if (!foundEmptySlot) {
            // No empty slot found
            throw Exception('No empty slots available in your wine fridge!');
          }
          
          // Update at the found empty position
          await widget.wineManager.updateWine(updatedBottle, row, col);
          
          // Update the grid immediately with the new values
          widget.wineManager.grid[row][col] = updatedBottle;
          widget.wineManager.notifyListeners(); // Force UI update
        }
        
        // Then refresh from database to ensure consistency
        await widget.wineManager.loadData();
        
        if (mounted) {
          Navigator.pop(context, updatedBottle);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Wine added to your collection'),
              backgroundColor: Colors.teal[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save wine: ${e.toString()}'),
            backgroundColor: Colors.red[700],
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

  Future<void> _selectEventPhoto() async {
    try {
      // Show a dialog to choose between camera and gallery
      final source = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Photo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      );
      
      if (source == null) return;
      
      // Import image_picker within this method to avoid unnecessary dependencies
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          eventPhotoFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
