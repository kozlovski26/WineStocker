import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/core/models/currency.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/wine_collection/domain/models/wine_bottle.dart';
import 'package:wine_inventory/features/wine_collection/services/gemini_service.dart';
import 'package:wine_inventory/features/wine_collection/services/settings_service.dart';
import 'package:wine_inventory/features/wine_collection/presentation/managers/wine_manager.dart';

class WineScanScreen extends StatefulWidget {
  final bool isPro;
  
  const WineScanScreen({
    Key? key, 
    this.isPro = false,
  }) : super(key: key);

  @override
  State<WineScanScreen> createState() => _WineScanScreenState();
}

class _WineScanScreenState extends State<WineScanScreen> {
  final SettingsService _settingsService = SettingsService();
  File? _imageFile;
  bool _isLoading = false;
  WineBottle? _analyzedWine;
  String? _errorMessage;
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;
  String _selectedModel = 'gemini-1.5-pro'; // Default model
  bool _isUserPro = false; // Track the Pro status locally

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadModelPreference();
    _checkProStatus(); // Check pro status on init
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkProStatus() async {
    bool isPro = widget.isPro; // Start with the prop value
    
    if (!isPro) {
      // Only check repository if not already Pro from props
      final wineManager = Provider.of<WineManager>(context, listen: false);
      if (wineManager.repository != null) {
        try {
          isPro = await wineManager.repository.isUserPro();
        } catch (e) {
          debugPrint('Error checking pro status: $e');
          isPro = false;
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _isUserPro = isPro;
      });
    }
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _settingsService.getGeminiApiKey();
    if (apiKey != null) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  Future<void> _loadModelPreference() async {
    final modelName = await _settingsService.getGeminiModel();
    setState(() {
      _selectedModel = modelName;
    });
  }

  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _analyzedWine = null;
          _errorMessage = null;
        });
        
        _analyzeWineImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking picture: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _analyzedWine = null;
          _errorMessage = null;
        });
        
        _analyzeWineImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _analyzeWineImage() async {
    // Hardcoded API key
    final apiKey = 'AIzaSyDjrSPjrVEjf5zuLfGlMHn3Ysda8lLz1kQ';
    
    if (_imageFile == null) {
      setState(() {
        _errorMessage = 'Please take or select an image first';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Save API key for future use
      await _settingsService.saveGeminiApiKey(apiKey);
      
      // Create GeminiService and analyze image with selected model
      final geminiService = GeminiService(
        apiKey: apiKey,
        modelName: _selectedModel,
      );
      
      final analyzedWine = await geminiService.analyzeWineImage(_imageFile!);
      
      setState(() {
        _analyzedWine = analyzedWine;
        _isLoading = false;
        if (analyzedWine == null) {
          _errorMessage = 'Failed to analyze wine image. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error analyzing wine: $e';
      });
    }
  }

  Future<void> _saveWineToCollection() async {
    if (_analyzedWine == null) return;
    
    try {
      // Set the captured image file path
      if (_imageFile != null) {
        // Return to previous screen with wine data and image file
        Navigator.pop(context, {
          'wine': _analyzedWine,
          'imageFile': _imageFile
        });
      } else {
        Navigator.pop(context, {
          'wine': _analyzedWine,
          'imageFile': null
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error returning wine data: $e';
      });
    }
  }

  // Save the selected model preference
  Future<void> _saveModelPreference(String modelName) async {
    await _settingsService.saveGeminiModel(modelName);
    setState(() {
      _selectedModel = modelName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Wine Label'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pro feature toggle section - more compact
              if (_isUserPro) _buildModelSelector(),
              
              // Main content
              if (_imageFile == null) 
                _buildImageSection()
              else
                Center(child: _buildImageSection()),
              
              const SizedBox(height: 14),
              _buildActions(),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorMessage(),
              ],
              
              if (_isLoading) ...[
                const SizedBox(height: 14),
                Center(child: _buildLoadingIndicator()),
              ],
              
              if (_analyzedWine != null && !_analyzedWine!.isEmpty) ...[
                const SizedBox(height: 20),
                _buildAnalysisResults(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 6),
          const Text(
            'AI Model:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Pro side with padding
          Container(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'Pro',
              style: TextStyle(
                fontSize: 12,
                color: _selectedModel == 'gemini-1.5-pro' 
                    ? Colors.teal.shade300 
                    : Colors.grey.shade400,
                fontWeight: _selectedModel == 'gemini-1.5-pro'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          // Switch with padding
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 50, // Fixed width for the switch
            child: Switch(
              value: _selectedModel == 'gemini-2.0-flash',
              onChanged: (value) {
                final newModel = value ? 'gemini-2.0-flash' : 'gemini-1.5-pro';
                _saveModelPreference(newModel);
              },
              activeColor: Colors.teal.shade300,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          // Flash side with padding
          Container(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Flash',
              style: TextStyle(
                fontSize: 12,
                color: _selectedModel == 'gemini-2.0-flash' 
                    ? Colors.teal.shade300 
                    : Colors.grey.shade400,
                fontWeight: _selectedModel == 'gemini-2.0-flash'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageSection() {
    if (_imageFile != null) {
      return Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade700, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(color: Colors.grey.shade700, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48, 
              color: Colors.teal.shade300
            ),
            const SizedBox(height: 14),
            const Text(
              'Take a photo of a wine bottle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'AI will analyze the label and extract details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActions() {
    if (_analyzedWine != null && !_analyzedWine!.isEmpty) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: _saveWineToCollection,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Add to Collection'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.teal.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: IconButton.outlined(
              onPressed: () {
                setState(() {
                  _imageFile = null;
                  _analyzedWine = null;
                });
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Scan New Wine',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_isUserPro)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _selectedModel == 'gemini-1.5-pro' 
                    ? '• Using Gemini 1.5 Pro: Better with details'
                    : '• Using Gemini 2.0 Flash: Faster analysis',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing with ${_selectedModel == 'gemini-1.5-pro' ? 'Gemini 1.5 Pro' : 'Gemini 2.0 Flash'}...',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final wine = _analyzedWine!;
    final wineManager = Provider.of<WineManager>(context, listen: false);
    
    // Get the user's currency preference (default to USD if not available)
    final Currency defaultCurrency = wineManager.settings.currency ?? Currency.USD;
    
    // Use the wine's currency if available, otherwise use the default
    Currency displayCurrency = defaultCurrency;
    if (wine.currency != null) {
      try {
        displayCurrency = Currency.values.firstWhere(
          (c) => c.name == wine.currency,
          orElse: () => defaultCurrency,
        );
      } catch (e) {
        debugPrint('Error parsing currency: $e');
      }
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wine_bar,
                  color: Colors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Analysis Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isUserPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade700, width: 0.5),
                    ),
                    child: Text(
                      _selectedModel == 'gemini-1.5-pro' ? 'Pro' : 'Flash',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _selectedModel == 'gemini-1.5-pro' 
                            ? Colors.teal.shade300 
                            : Colors.amber.shade300,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),
            _buildWineDetail('Name', wine.name ?? 'Unknown'),
            _buildWineDetail('Winery', wine.winery ?? 'Unknown'),
            _buildWineDetail('Year', wine.year ?? 'Unknown'),
            _buildWineDetail('Type', _wineTypeToString(wine.type)),
            if (wine.country != null)
              _buildWineDetail('Country', wine.country!),
            if (wine.price != null)
              _buildWineDetail('Price', wine.price!.toStringAsFixed(2)),
            _buildWineDetail('Notes', wine.notes ?? 'None'),
          ],
        ),
      ),
    );
  }

  Widget _buildWineDetail(String label, String value) {
    // Trim extremely long values to prevent layout issues
    String displayValue = value;
    if (value.length > 100) {
      displayValue = '${value.substring(0, 97)}...';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80, // Increased width to accommodate all labels
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _wineTypeToString(WineType? type) {
    if (type == null) return 'Unknown';
    
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'Enter your Gemini API key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showApiKey = !_showApiKey;
                    });
                  },
                ),
              ),
              obscureText: !_showApiKey,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a Gemini API key from the Google AI Studio website.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = _apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                await _settingsService.saveGeminiApiKey(apiKey);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API key saved')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 