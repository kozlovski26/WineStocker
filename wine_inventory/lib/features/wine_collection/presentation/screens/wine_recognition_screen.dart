import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/wine_collection/domain/models/wine_bottle.dart';
import 'package:wine_inventory/features/wine_collection/presentation/managers/wine_manager.dart';


class WineRecognitionScreen extends StatefulWidget {
  final File? initialImageFile;
  final WineBottle? initialWine;

  const WineRecognitionScreen({
    super.key,
    this.initialImageFile,
    this.initialWine,
  });

  @override
  State<WineRecognitionScreen> createState() => _WineRecognitionScreenState();
}

class _WineRecognitionScreenState extends State<WineRecognitionScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  bool _isAddingToCollection = false;
  WineBottle? _recognizedWine;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize with provided image and wine data if available
    _imageFile = widget.initialImageFile;
    _recognizedWine = widget.initialWine;
    
    // If we have an image but no recognized wine, analyze it
    if (_imageFile != null && _recognizedWine == null) {
      _analyzeWine();
    }
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
        _recognizedWine = null;
        _errorMessage = null;
      });
      _analyzeWine();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _recognizedWine = null;
        _errorMessage = null;
      });
      _analyzeWine();
    }
  }

  Future<void> _analyzeWine() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with your actual AI wine recognition API
      // This is a mock implementation
      await Future.delayed(const Duration(seconds: 2)); // Simulate API delay
      
      // Mock recognized wine data
      final mockData = {
        'name': 'Château Margaux 2015',
        'winery': 'Château Margaux',
        'year': '2015',
        'type': WineType.red.index,
        'country': 'France',
        'price': 499.99,
        'notes': 'Exceptional vintage with rich black fruit, tobacco, and cedar notes. Elegant tannins with long finish.',
      };
      
      setState(() {
        _recognizedWine = WineBottle(
          name: mockData['name'] as String,
          winery: mockData['winery'] as String,
          year: mockData['year'] as String,
          type: WineType.values[mockData['type'] as int],
          country: mockData['country'] as String,
          price: mockData['price'] as double,
          notes: mockData['notes'] as String,
          dateAdded: DateTime.now(),
          source: WineSource.drinkList, // Wine recognized from external location
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze wine: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _addWineToDrunkList() async {
    if (_recognizedWine == null || _imageFile == null) return;

    final wineManager = Provider.of<WineManager>(context, listen: false);
    setState(() {
      _isAddingToCollection = true;
    });

    try {
      // Create a copy with isDrunk set to true and dateDrunk as now
      final drunkWine = _recognizedWine!.copyWith(
        isDrunk: true,
        dateDrunk: DateTime.now(),
      );
      
      // Add to drunk wines collection with the image file
      await wineManager.addDrunkWine(drunkWine, imageFile: _imageFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${drunkWine.name} added to your drinking history!'),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding wine: ${e.toString()}'),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isAddingToCollection = false;
      });
    }
  }

  Widget _buildWineInfo() {
    if (_recognizedWine == null) return const SizedBox.shrink();
    
    final primaryColor = Theme.of(context).colorScheme.primary; // Should be red[400]
    final secondaryColor = Theme.of(context).colorScheme.secondary; // Should be red[200]
    final surfaceColor = Theme.of(context).colorScheme.surface; // Dark surface color
    
    // Add a variable to track if wine is from fridge or external source
    bool isExternalSource = _recognizedWine!.source == WineSource.drinkList;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recognized Wine',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', _recognizedWine!.name ?? 'Unknown'),
          _buildInfoRow('Winery', _recognizedWine!.winery ?? 'Unknown'),
          _buildInfoRow('Year', _recognizedWine!.year ?? 'Unknown'),
          _buildInfoRow('Type', _recognizedWine!.type != null 
              ? _getWineTypeName(_recognizedWine!.type!) 
              : 'Unknown'),
          _buildInfoRow('Country', _recognizedWine!.country ?? 'Unknown'),
          _buildInfoRow('Price', _recognizedWine!.price != null 
              ? '\$${_recognizedWine!.price!.toStringAsFixed(2)}' 
              : 'Unknown'),
          if (_recognizedWine!.notes != null) 
            const SizedBox(height: 8),
          if (_recognizedWine!.notes != null)
            Text(
              'Notes:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          if (_recognizedWine!.notes != null)
            Text(
              _recognizedWine!.notes!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 16),
          
          // Add wine location selection
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Fridge option
                InkWell(
                  onTap: () {
                    setState(() {
                      _recognizedWine = _recognizedWine!.copyWith(
                        source: WineSource.fridge,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !isExternalSource 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.transparent,
                      border: Border.all(
                        color: !isExternalSource 
                            ? Colors.blue[300]! 
                            : Colors.grey[700]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.kitchen_outlined,
                          color: !isExternalSource 
                              ? Colors.blue[300] 
                              : Colors.grey[500],
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wine Fridge',
                                style: TextStyle(
                                  color: !isExternalSource 
                                      ? Colors.blue[300] 
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Store in your wine fridge collection',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<bool>(
                          value: false,
                          groupValue: isExternalSource,
                          activeColor: Colors.blue[300],
                          onChanged: (bool? value) {
                            if (value != null && value == false) {
                              setState(() {
                                _recognizedWine = _recognizedWine!.copyWith(
                                  source: WineSource.fridge,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // External option
                InkWell(
                  onTap: () {
                    setState(() {
                      _recognizedWine = _recognizedWine!.copyWith(
                        source: WineSource.drinkList,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExternalSource 
                          ? Colors.amber.withOpacity(0.1) 
                          : Colors.transparent,
                      border: Border.all(
                        color: isExternalSource 
                            ? Colors.amber[400]! 
                            : Colors.grey[700]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wine_bar_outlined,
                          color: isExternalSource 
                              ? Colors.amber[400] 
                              : Colors.grey[500],
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'External Storage',
                                style: TextStyle(
                                  color: isExternalSource 
                                      ? Colors.amber[400] 
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Wine stored elsewhere (not in your fridge)',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<bool>(
                          value: true,
                          groupValue: isExternalSource,
                          activeColor: Colors.amber[400],
                          onChanged: (bool? value) {
                            if (value != null && value == true) {
                              setState(() {
                                _recognizedWine = _recognizedWine!.copyWith(
                                  source: WineSource.drinkList,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isAddingToCollection ? null : _addWineToDrunkList,
                  icon: _isAddingToCollection 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white)
                        ) 
                      : const Icon(Icons.wine_bar),
                  label: const Text('Add to Drunk List'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement adding to collection
                    // This would require selecting a grid position
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature is coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Add to Collection'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWineTypeName(WineType type) {
    switch (type) {
      case WineType.red:
        return 'Red';
      case WineType.white:
        return 'White';
      case WineType.rose:
        return 'Rosé';
      case WineType.sparkling:
        return 'Sparkling';
      case WineType.dessert:
        return 'Dessert';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get app theme colors
    final primaryColor = Theme.of(context).colorScheme.primary; // Should be red[400]
    final secondaryColor = Theme.of(context).colorScheme.secondary; // Should be red[200]
    final surfaceColor = Theme.of(context).colorScheme.surface; // Dark surface color
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wine Recognition',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_imageFile != null)
                  Container(
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                          if (_isAnalyzing)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Analyzing wine...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_imageFile == null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Take a photo of a wine bottle',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our AI will identify the wine and provide details',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_recognizedWine != null) _buildWineInfo(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isAnalyzing ? null : _takePicture,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isAnalyzing ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 