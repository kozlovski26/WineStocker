import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/wine_bottle.dart';
import '../managers/wine_manager.dart';
import '../../utils/wine_type_helper.dart';
import './wine_details_dialog.dart';
import './wine_edit_dialog.dart';
import '../../../../core/models/currency.dart';
import '../screens/wine_photo_screen.dart';
import '../../services/gemini_service.dart';

// Define the enum at the top level, outside any class
enum SortCriteria { date, name, type, price }

class DrunkWinesDialog extends StatefulWidget {
  final WineManager wineManager;

  const DrunkWinesDialog({
    super.key,
    required this.wineManager,
  });

  @override
  State<DrunkWinesDialog> createState() => _DrunkWinesDialogState();
}

class _DrunkWinesDialogState extends State<DrunkWinesDialog> {
  // Sorting options
  SortCriteria _currentSortCriteria = SortCriteria.date;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final sortedDrunkWines = _getSortedWines();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSortOptions(),
            if (sortedDrunkWines.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: sortedDrunkWines.length,
                  itemBuilder: (context, index) {
                    final wine = sortedDrunkWines[index];
                    return Dismissible(
                      key: ObjectKey(wine),
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red[900]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => _handleDismiss(context, wine),
                      child: _buildWineCard(context, wine),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<WineBottle> _getSortedWines() {
    final wines = List<WineBottle>.from(widget.wineManager.drunkWines);
    
    wines.sort((a, b) {
      int comparison = 0; // Initialize with a default value
      
      switch (_currentSortCriteria) {
        case SortCriteria.date:
          comparison = (a.dateDrunk ?? DateTime.now())
              .compareTo(b.dateDrunk ?? DateTime.now());
          break;
        case SortCriteria.name:
          comparison = (a.name ?? '').compareTo(b.name ?? '');
          break;
        case SortCriteria.type:
          final aType = a.type?.index ?? -1;
          final bType = b.type?.index ?? -1;
          comparison = aType.compareTo(bType);
          break;
        case SortCriteria.price:
          final aPrice = a.price ?? 0;
          final bPrice = b.price ?? 0;
          comparison = aPrice.compareTo(bPrice);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return wines;
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSortChip(
              label: 'Date', 
              criteria: SortCriteria.date,
              icon: Icons.calendar_today,
            ),
            const SizedBox(width: 8),
            _buildSortChip(
              label: 'Name', 
              criteria: SortCriteria.name,
              icon: Icons.sort_by_alpha,
            ),
            const SizedBox(width: 8),
            _buildSortChip(
              label: 'Type', 
              criteria: SortCriteria.type,
              icon: Icons.wine_bar,
            ),
            const SizedBox(width: 8),
            _buildSortChip(
              label: 'Price', 
              criteria: SortCriteria.price,
              icon: Icons.attach_money,
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber[800]!.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: Colors.amber[300],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _sortAscending ? 'Ascending' : 'Descending',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required SortCriteria criteria,
    required IconData icon,
  }) {
    final isSelected = _currentSortCriteria == criteria;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSortCriteria = criteria;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.red[900]?.withOpacity(0.3) 
              : Colors.grey[850]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.red[800]!.withOpacity(0.5)
                : Colors.grey[700]!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.amber[300] : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWineCard(BuildContext context, WineBottle wine) {
    // Get color based on wine type, defaulting to deep purple
    Color wineColor = Colors.deepPurple;
    if (wine.type != null) {
      wineColor = WineTypeHelper.getTypeColor(wine.type!);
    }
    
    // Format price if available
    String? priceString;
    if (wine.price != null) {
      priceString = wine.price!.toStringAsFixed(2);
    }
    
    // Check if wine has an event photo
    final hasEventPhoto = wine.metadata != null && wine.metadata!['eventPhotoUrl'] != null;
    final eventPhotoUrl = hasEventPhoto ? wine.metadata!['eventPhotoUrl'] as String : null;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showWineDetails(context, wine),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                wineColor.withOpacity(0.15),
                Colors.grey[900]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Wine and event photo images column
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      // Wine bottle image
                      Hero(
                        tag: 'wine-image-${wine.hashCode}',
                        child: Container(
                          width: 50,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: wine.imagePath != null
                                ? CachedNetworkImage(
                                    imageUrl: wine.imagePath!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => _buildPlaceholderImage(),
                                    placeholder: (context, url) => _buildLoadingImage(),
                                  )
                                : _buildPlaceholderImage(),
                          ),
                        ),
                      ),
                      
                      // Event photo thumbnail
                      if (hasEventPhoto)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: CachedNetworkImage(
                                    imageUrl: eventPhotoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.black26,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.black26,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.amber[300],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[900]!.withOpacity(0.8),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(7),
                                      bottomLeft: Radius.circular(7),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Wine details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Wine name and date
                      Row(
                        children: [
                          // Wine name
                          Expanded(
                            child: Text(
                              wine.name ?? 'Unnamed Wine',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Date drunk
                          if (wine.dateDrunk != null)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 4),
                              child: Text(
                                DateFormat.MMMd().format(wine.dateDrunk!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Winery
                      if (wine.winery != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          wine.winery!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Year and price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (wine.year != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                wine.year!,
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          
                          if (priceString != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 6),
                              child: Text(
                                priceString,
                                style: TextStyle(
                                  color: Colors.green[300],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Add to Fridge button - improved styling
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        child: InkWell(
                          onTap: () => _showGridSelectionDialog(context, wine),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[700]!.withOpacity(0.7),
                                  Colors.green[900]!.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green[400]!.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.kitchen,
                                  size: 14,
                                  color: Colors.green[100],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add to Fridge',
                                  style: TextStyle(
                                    color: Colors.green[100],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWineInfoSection(WineBottle wine, Color wineColor) {
    String? priceString;
    if (wine.price != null) {
      priceString = wine.price!.toStringAsFixed(2);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wine.dateDrunk != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              DateFormat.yMd().format(wine.dateDrunk!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          wine.name ?? 'Unnamed Wine',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (wine.winery != null) ...[
          const SizedBox(height: 2),
          Text(
            wine.winery!,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            if (wine.year != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wine.year!,
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            if (wine.year != null && wine.country != null)
              const SizedBox(width: 8),
            if (wine.country != null)
              Text(
                wine.country!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
            if (priceString != null) ...[
              const Spacer(),
              Text(
                priceString,
                style: TextStyle(
                  color: Colors.green[300],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: OutlinedButton.icon(
                onPressed: () => _showGridSelectionDialog(context, wine),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  'Add to Fridge',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[400],
                  backgroundColor: Colors.green[900]?.withOpacity(0.2),
                  side: BorderSide(color: Colors.green[400]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(120, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.wine_bar_outlined,
                    size: 28,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Drunk Wines',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // Add button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.red[300],
                      size: 26,
                    ),
                  ),
                  onPressed: () async {
                    // Check if user is Pro, for AI recognition
                    final isPro = await widget.wineManager.repository.isUserPro();
                    
                    // Navigate to WinePhotoScreen to take or select a photo
                    final photoPath = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (context) => WinePhotoScreen(isPro: isPro)),
                    );
                    
                    // If user canceled or something went wrong
                    if (photoPath == null || !mounted) return;
                    
                    // Process the image
                    final File imageFile = File(photoPath);
                    
                    // Check if user is Pro for AI analysis
                    if (isPro) {
                      // Show loading indicator for Pro users
                      _showLoadingDialog('Analyzing wine image...');
                      
                      // Get the API key
                      const String geminiApiKey = 'AIzaSyDjrSPjrVEjf5zuLfGlMHn3Ysda8lLz1kQ';
                      
                      // Create GeminiService and analyze image
                      final geminiService = GeminiService(
                        apiKey: geminiApiKey,
                        modelName: 'gemini-2.0-flash',
                      );
                      
                      try {
                        final analyzedWine = await geminiService.analyzeWineImage(imageFile);
                        
                        // Close loading dialog
                        if (mounted) Navigator.of(context).pop();
                        
                        if (analyzedWine == null) {
                          // Analysis failed, show the empty edit dialog
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Could not fully analyze the wine label. Please fill in any missing details.',
                                ),
                                backgroundColor: Colors.orange[700],
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            
                            _showEmptyWineEditDialog(imageFile);
                          }
                        } else {
                          // Analysis succeeded, show success message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Wine label analyzed successfully! Please verify and adjust details if needed.',
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                          
                          // Show edit dialog with pre-filled data
                          _showWineEditDialogWithData(analyzedWine, imageFile);
                        }
                      } catch (e) {
                        // Close loading dialog
                        if (mounted) Navigator.of(context).pop();
                        
                        // Show error and continue with empty edit dialog
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error analyzing wine: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          
                          _showEmptyWineEditDialog(imageFile);
                        }
                      }
                    } else {
                      // Non-Pro users skip AI analysis and go directly to manual entry
                      _showEmptyWineEditDialog(imageFile);
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[800], thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wine_bar_outlined,
                size: 80,
                color: Colors.red[300]?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No drunk wines yet',
              style: GoogleFonts.playfairDisplay(
                color: Colors.grey[300],
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Your wine drinking history will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Icon(
          Icons.wine_bar,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      ),
    );
  }

  void _showWineDetails(BuildContext context, WineBottle wine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WineDetailsDialog(
        bottle: wine,
        wineManager: widget.wineManager,
        row: -1,
        col: -1,
        isDrunkWine: true,
      ),
    ).then((_) {
      // Force a refresh of the UI when returning from details dialog
      // This ensures any added event photos will show their indicators
      if (mounted) {
        setState(() {
          // Update the local state to reflect any changes made in the details dialog
          // The metadata updates are already saved in the WineManager
        });
      }
    });
  }

  void _handleDismiss(BuildContext context, WineBottle wine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isProcessing = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Delete from History',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to remove this wine from your drinking history?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing 
                    ? null 
                    : () {
                        Navigator.pop(context);
                        // Rebuild the list to restore the item
                        this.setState(() {});
                      },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: isProcessing
                    ? null
                    : () async {
                        setState(() => isProcessing = true);
                        try {
                          await widget.wineManager.removeDrunkWine(wine);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wine removed from history'),
                                backgroundColor: Colors.red[900],
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red[900],
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                  child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGridSelectionDialog(BuildContext context, WineBottle wine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                bool isProcessing = false;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with wine info
                    Row(
                      children: [
                        // Small wine image
                        if (wine.imagePath != null)
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
                              child: CachedNetworkImage(
                                imageUrl: wine.imagePath!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _buildPlaceholderImage(),
                                placeholder: (context, url) => _buildLoadingImage(),
                              ),
                            ),
                          ),
                        // Wine details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wine.name ?? 'Unnamed Wine',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (wine.winery != null)
                                Text(
                                  wine.winery!,
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
                          onPressed: () => Navigator.pop(context),
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
                                      widget.wineManager.settings.rows,
                                      (row) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          widget.wineManager.settings.columns,
                                          (col) {
                                            final currentBottle = widget.wineManager.grid[row][col];
                                            final isEmpty = currentBottle.isEmpty;
                                            return Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: isEmpty && !isProcessing
                                                    ? () async {
                                                        setState(() => isProcessing = true);
                                                        await _restoreToPosition(context, wine, row, col);
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

  Future<void> _restoreToPosition(
    BuildContext context,
    WineBottle wine,
    int row,
    int col,
  ) async {
    try {
      // Create restored wine
      final restoredWine = wine.copyWith(
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
            content: Text('${wine.name} added to fridge'),
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
            content: Text('Error adding wine: ${e.toString()}'),
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Our AI is examining the wine label to identify details such as name, winery, year, and type.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmptyWineEditDialog(File imageFile) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => WineEditDialog(
        bottle: WineBottle(
          imagePath: imageFile.path,
          source: WineSource.drinkList,
          dateAdded: DateTime.now(),
        ),
        wineManager: widget.wineManager,
        row: -1, // Not in grid
        col: -1, // Not in grid
        tempImageFile: imageFile,
        defaultSource: WineSource.drinkList, // Force drink list source
      ),
    ).then((_) {
      // Refresh the list when returning from add
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showWineEditDialogWithData(WineBottle analyzedWine, File imageFile) {
    if (!mounted) return;
    
    // Update the analyzed wine with the image path and ensure drink list source
    final bottleToEdit = analyzedWine.copyWith(
      imagePath: imageFile.path,
      source: WineSource.drinkList,
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => WineEditDialog(
        bottle: bottleToEdit,
        wineManager: widget.wineManager,
        row: -1, // Not in grid
        col: -1, // Not in grid
        isEdit: false,
        tempImageFile: imageFile,
        defaultSource: WineSource.drinkList, // Force drink list source
      ),
    ).then((_) {
      // Refresh the list when returning from add
      if (mounted) {
        setState(() {});
      }
    });
  }
}