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
import '../../../../core/models/wine_country.dart';
import '../widgets/country_selector.dart';
import 'package:image_picker/image_picker.dart';

class WineDetailsDialog extends StatefulWidget {
  final WineBottle bottle;
  final WineManager wineManager;
  final int row;
  final int col;
  final bool isDrunkWine;
  final VoidCallback? onDrinkWine;

  const WineDetailsDialog({
    super.key,
    required this.bottle,
    required this.wineManager,
    required this.row,
    required this.col,
    this.isDrunkWine = false,
    this.onDrinkWine,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
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
    
    // Check if there's an event photo
    final hasEventPhoto = _bottle.metadata != null && _bottle.metadata!['eventPhotoUrl'] != null;
    final eventPhotoUrl = hasEventPhoto ? _bottle.metadata!['eventPhotoUrl'] as String : null;
    
    return Column(
      children: [
        if (hasEventPhoto && widget.isDrunkWine)
          // Tabs for switching between bottle and event photos
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  height: 45,
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: typeColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Wine Bottle'),
                      Tab(text: 'Event Photo'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      // Wine Bottle Photo Tab
                      _buildBottlePhoto(),
                      // Event Photo Tab
                      GestureDetector(
                        onTap: () => _showEventPhoto(context, eventPhotoUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CachedNetworkImage(
                            imageUrl: eventPhotoUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.amber[400], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load event photo',
                                    style: TextStyle(color: Colors.amber[400]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (widget.isDrunkWine) // For drunk wines without an event photo
          Column(
            children: [
              _buildBottlePhoto(),
              // Add Event Photo button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _addEventPhoto,
                    icon: const Icon(
                      Icons.add_a_photo,
                      size: 20,
                    ),
                    label: const Text(
                      'Add Event Photo',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Just show bottle photo without tabs for non-drunk wines
          _buildBottlePhoto(),
      ],
    );
  }
  
  Widget _buildBottlePhoto() {
    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          child: _bottle.imagePath != null
              ? widget.isDrunkWine 
                ? (_bottle.imagePath!.startsWith('http')
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
                      ))
                : GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WinePhotoScreen(isPro: false),
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
        if (_isEditing && !widget.isDrunkWine)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _handleImageSelection,
              backgroundColor: _bottle.type != null ? WineTypeHelper.getTypeColor(_bottle.type!) : Colors.red[400]!.withOpacity(0.9),
              child: const Icon(Icons.camera_alt, size: 20),
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
          
          // Country
          _buildCountrySection(),

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

  Widget _buildCountryDisplay() {
    if (_bottle.country == null || _bottle.country!.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          WineCountry.getFlagForCountry(_bottle.country) ?? '🍷',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _bottle.country!,
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

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isEditing
            ? CountrySelector(
                selectedCountry: _bottle.country,
                onCountrySelected: (country) {
                  setState(() => _bottle.country = country);
                },
              )
            : _buildCountryDisplay(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        // Add date drunk for drunk wines
        if (widget.isDrunkWine && _bottle.dateDrunk != null) ...[
          const SizedBox(height: 24),
          _buildInfoColumn(
            'DRUNK ON',
            DateFormat('MMMM d, y').format(_bottle.dateDrunk!),
            Colors.purple[300]!,
          ),
        ],
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
    if (widget.isDrunkWine) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => _showGridSelectionDialog(context),
          icon: const Icon(Icons.restore),
          label: const Text('Got Another'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green[700],
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    if (_isEditing) {
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
    
    // Display just the edit button in non-edit mode
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _toggleEditMode,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[400],
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          // Add Drink Wine button next to Edit button
          if (!widget.isDrunkWine && widget.onDrinkWine != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading ? null : widget.onDrinkWine,
                icon: const Icon(Icons.wine_bar),
                label: const Text('Drink'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
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
        country: _bottle.country,
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
        builder: (context) => const WinePhotoScreen(isPro: false),
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

  void _showGridSelectionDialog(BuildContext context) {
    Navigator.pop(context); // Close details dialog
    
    // Get the original drunk wines dialog context
    final originalContext = Navigator.of(context).context;
    
    if (originalContext.mounted) {
      // Find the parent DrunkWinesDialog state
      final drunkWinesDialog = Navigator.of(originalContext).widget as dynamic;
      final wineManager = widget.wineManager;
      
      // Call the grid selection dialog from the drunk wines class directly
      if (context.mounted) {
        showDialog(
          context: originalContext,
          builder: (BuildContext ctx) {
            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                ),
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    bool isProcessing = false;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with wine info
                        Row(
                          children: [
                            // Small wine image
                            if (_bottle.imagePath != null)
                              Container(
                                width: 40,
                                height: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _bottle.imagePath!.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: _bottle.imagePath!,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[850],
                                          child: Icon(Icons.wine_bar, size: 20, color: Colors.grey[600]),
                                        ),
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[850],
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                      )
                                    : Image.file(
                                        File(_bottle.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey[850],
                                          child: Icon(Icons.wine_bar, size: 20, color: Colors.grey[600]),
                                        ),
                                      ),
                                ),
                              ),
                            // Wine details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _bottle.name ?? 'Unnamed Wine',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_bottle.winery != null)
                                    Text(
                                      _bottle.winery!,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Close button
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Title and instructions
                        Text(
                          'Add to Your Fridge',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[900]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[800]!.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.green[300]),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Tap an empty slot (green) to add this wine',
                                  style: TextStyle(
                                    color: Colors.green[100],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Grid
                        Flexible(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[800]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          wineManager.settings.rows,
                                          (row) => Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              wineManager.settings.columns,
                                              (col) {
                                                final currentBottle = wineManager.grid[row][col];
                                                final isEmpty = currentBottle.isEmpty;
                                                return Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: isEmpty && !isProcessing
                                                        ? () async {
                                                            setState(() => isProcessing = true);
                                                            await _restoreToPosition(ctx, row, col);
                                                          }
                                                        : null,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration: BoxDecoration(
                                                          color: isEmpty 
                                                            ? Colors.green.withOpacity(0.2)
                                                            : Colors.red.withOpacity(0.2),
                                                          border: Border.all(
                                                            color: isEmpty 
                                                              ? Colors.green.withOpacity(0.5)
                                                              : Colors.red.withOpacity(0.5),
                                                            width: 1,
                                                          ),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Center(
                                                          child: isEmpty
                                                            ? Icon(
                                                                Icons.add,
                                                                color: Colors.green[400],
                                                                size: 20,
                                                              )
                                                            : Stack(
                                                                alignment: Alignment.center,
                                                                children: [
                                                                  Icon(
                                                                    Icons.wine_bar,
                                                                    color: Colors.red[400],
                                                                    size: 20,
                                                                  ),
                                                                  Positioned(
                                                                    right: 0,
                                                                    bottom: 0,
                                                                    child: Container(
                                                                      width: 12,
                                                                      height: 12,
                                                                      decoration: const BoxDecoration(
                                                                        color: Colors.black54,
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons.block,
                                                                        color: Colors.white,
                                                                        size: 8,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isProcessing)
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Adding wine to fridge...',
                                          style: TextStyle(
                                            color: Colors.white,
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
                        
                        const SizedBox(height: 8),
                        
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(Icons.add, 'Available', Colors.green[400]!),
                            const SizedBox(width: 24),
                            _buildLegendItem(Icons.wine_bar, 'Occupied', Colors.red[400]!),
                          ],
                        ),
                      ],
                    );
                  }
                ),
              ),
            );
          },
        );
      }
    }
  }
  
  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _restoreToPosition(BuildContext context, int row, int col) async {
    try {
      // Create restored wine
      final restoredWine = _bottle.copyWith(
        isDrunk: false,
        dateDrunk: null,
        dateAdded: DateTime.now(),
      );

      // Update grid
      await widget.wineManager.updateWine(restoredWine, row, col);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_bottle.name} copied to collection'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring wine: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showEventPhoto(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Failed to load image: $error'),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addEventPhoto() async {
    try {
      setState(() => _isLoading = true);
      
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
      
      setState(() => _isLoading = false);
      
      if (source == null || !mounted) return;
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() => _isLoading = true);
        
        // Upload event photo
        try {
          final eventPhotoFile = File(image.path);
          final eventPhotoUrl = await widget.wineManager.repository.uploadWineImage(eventPhotoFile.path);
          
          if (eventPhotoUrl != null && mounted) {
            // Update wine metadata with event photo URL
            final updatedMetadata = {..._bottle.metadata ?? {}, 'eventPhotoUrl': eventPhotoUrl};
            final updatedBottle = _bottle.copyWith(metadata: updatedMetadata);
            
            // Update the bottle in the drunk wines list
            await widget.wineManager.updateDrunkWine(updatedBottle);
            
            if (mounted) {
              setState(() {
                _bottle = updatedBottle;
                widget.bottle.metadata = updatedMetadata;
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Event photo added successfully'),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add event photo: ${e.toString()}'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

