import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_cropper/image_cropper.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WineFridgeApp());
}

class WineFridgeApp extends StatelessWidget {
  const WineFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wine Collection',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.red[400]!,
          secondary: Colors.red[200]!,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const WineFridgeGrid(),
    );
  }
}

enum WineType { red, white, sparkling, rose, dessert }

class WineBottle {
  String? name;
  String? year;
  String? notes;
  DateTime? dateAdded;
  DateTime? dateDrunk; // New field
  String? imagePath;
  WineType? type;
  double? rating;
  bool isFavorite;
  bool isDrunk; // New field

  WineBottle({
    this.name,
    this.year,
    this.notes,
    this.dateAdded,
    this.dateDrunk,
    this.imagePath,
    this.type,
    this.rating,
    this.isFavorite = false,
    this.isDrunk = false,
  });

  bool get isEmpty => name == null && imagePath == null;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'notes': notes,
      'dateAdded': dateAdded?.toIso8601String(),
      'dateDrunk': dateDrunk?.toIso8601String(),
      'imagePath': imagePath,
      'type': type?.index,
      'rating': rating,
      'isFavorite': isFavorite,
      'isDrunk': isDrunk,
    };
  }

  WineBottle.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        year = json['year'],
        notes = json['notes'],
        dateAdded = json['dateAdded'] != null
            ? DateTime.parse(json['dateAdded'])
            : null,
        dateDrunk = json['dateDrunk'] != null
            ? DateTime.parse(json['dateDrunk'])
            : null,
        imagePath = json['imagePath'],
        type = json['type'] != null ? WineType.values[json['type']] : null,
        rating = json['rating']?.toDouble(),
        isFavorite = json['isFavorite'] ?? false,
        isDrunk = json['isDrunk'] ?? false;
}

class GridSettings {
  final int rows;
  final int columns;

  GridSettings({required this.rows, required this.columns});

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'columns': columns,
      };

  factory GridSettings.fromJson(Map<String, dynamic> json) {
    return GridSettings(
      rows: json['rows'] ?? 4,
      columns: json['columns'] ?? 3,
    );
  }

  factory GridSettings.defaultSettings() {
    return GridSettings(rows: 4, columns: 3);
  }
}

class WineTypeButton extends StatelessWidget {
  final WineType type;
  final bool isSelected;
  final VoidCallback onTap;

  const WineTypeButton({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      WineType.red => Colors.red[400],
      WineType.white => Colors.amber[400],
      WineType.sparkling => Colors.blue[400],
      WineType.rose => Colors.pink[300],
      WineType.dessert => Colors.orange[400],
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color?.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color! : Colors.grey[700]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type.name[0].toUpperCase() + type.name.substring(1),
          style: TextStyle(
            color: isSelected ? color : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class WineFridgeGrid extends StatefulWidget {
  const WineFridgeGrid({super.key});

  @override
  WineFridgeGridState createState() => WineFridgeGridState();
}

class WineFridgeGridState extends State<WineFridgeGrid>
    with SingleTickerProviderStateMixin {
  late List<List<WineBottle>> grid;
  final ImagePicker _picker = ImagePicker();
  late GridSettings settings;
  int totalBottles = 0;
  bool isGridView = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  WineType? _selectedFilter;
  WineBottle? _copiedWine;
  bool _hasCopiedWine = false;
  List<WineBottle> drunkWines = []; // Add this line
  // Make sure to add these properties to your WineFridgeGridState class:

  @override
  void initState() {
    super.initState();
    settings = GridSettings.defaultSettings();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadSettings().then((_) => _loadData());
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSettingsDialog() {
    int tempRows = settings.rows;
    int tempColumns = settings.columns;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Grid Settings',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Rows: $tempRows',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: tempRows.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (value) {
                  setState(() {
                    tempRows = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Columns: $tempColumns',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: tempColumns.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                onChanged: (value) {
                  setState(() {
                    tempColumns = value.round();
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                settings = GridSettings(
                  rows: tempRows,
                  columns: tempColumns,
                );
              });
              await prefs.setString(
                'grid_settings',
                json.encode(settings.toJson()),
              );
              _loadData();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsData = prefs.getString('grid_settings');
      if (settingsData != null) {
        setState(() {
          settings = GridSettings.fromJson(json.decode(settingsData));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load settings');
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


Future<void> _handleWineBottle(int row, int col, {bool isEdit = false}) async {
  final bottle = grid[row][col];
  final TextEditingController nameController =
      TextEditingController(text: bottle.name);
  final TextEditingController notesController =
      TextEditingController(text: bottle.notes);
  String? selectedYear = bottle.year;
  WineType? selectedType = bottle.type;
  double? selectedRating = bottle.rating;
  bool isFavorite = bottle.isFavorite;
  bool hasPhoto = bottle.imagePath != null;

  // Generate years list from 1950 to current year
  final List<String> years = List.generate(DateTime.now().year - 1950 + 1,
      (index) => (DateTime.now().year - index).toString());

  int initialYearIndex = years.indexOf(selectedYear ?? years[0]);
  if (initialYearIndex < 0) initialYearIndex = 0;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
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
                // Header with Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Wine' : 'Add Wine',
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
                ),
                const SizedBox(height: 24),

                // Wine Name
                TextField(
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
                ),
                const SizedBox(height: 24),

                // Wine Type
                const Text(
                  'Wine Type:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: WineType.values.map((type) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedType = type;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: BorderSide(
                              color: selectedType == type
                                  ? Colors.red[400]!
                                  : Colors.white24,
                            ),
                            backgroundColor: selectedType == type
                                ? Colors.red[400]!.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: Text(
                            type.name,
                            style: TextStyle(
                              color: selectedType == type
                                  ? Colors.red[400]
                                  : Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Year Selector and Favorite Icon
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                            ),
                            builder: (context) => StatefulBuilder(
                              builder: (context, setModalState) => Container(
                                height: 300,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[600],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListWheelScrollView.useDelegate(
                                        controller: FixedExtentScrollController(
                                            initialItem: initialYearIndex),
                                        itemExtent: 40,
                                        perspective: 0.005,
                                        diameterRatio: 1.2,
                                        physics: const FixedExtentScrollPhysics(),
                                        onSelectedItemChanged: (index) {
                                          setModalState(() {
                                            selectedYear = years[index];
                                          });
                                          setState(() {
                                            selectedYear = years[index];
                                          });
                                        },
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          childCount: years.length,
                                          builder: (context, index) {
                                            final isSelected = years[index] == selectedYear;
                                            return Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                years[index],
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: isSelected ? Colors.red[400] : Colors.white70,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red[400],
                                        ),
                                        child: const Text('Confirm'),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedYear ?? 'Select Year',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 24),

                // Tasting Notes (always visible)
                TextField(
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
                ),
                const SizedBox(height: 24),

                // Photo Selection
                if (hasPhoto)
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
                      child: Image.file(
                        File(bottle.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
                        },
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _handleImageSelection(context, bottle);
                      setState(() {
                        hasPhoto = bottle.imagePath != null;
                      });
                    },
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
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      this.setState(() {
                        bottle.name = nameController.text;
                        bottle.year = selectedYear;
                        bottle.type = selectedType;
                        bottle.rating = selectedRating;
                        bottle.isFavorite = isFavorite;
                        bottle.notes = notesController.text;
                        if (!isEdit) {
                          bottle.dateAdded = DateTime.now();
                        }
                      });
                      _saveData();
                      Navigator.of(context).pop();
                    },
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
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
  
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? gridData = prefs.getString('wine_grid');
      final String? drunkData = prefs.getString('drunk_wines');

      setState(() {
        // Initialize empty grid
        grid = List.generate(
          settings.rows,
          (i) => List.generate(settings.columns, (j) => WineBottle()),
        );

        // Load active wines
        if (gridData != null) {
          final List<dynamic> decodedData = json.decode(gridData);
          int dataIndex = 0;

          // Fill grid with existing wines
          for (int i = 0;
              i < settings.rows && dataIndex < decodedData.length;
              i++) {
            for (int j = 0;
                j < settings.columns && dataIndex < decodedData.length;
                j++) {
              final bottleData = decodedData[dataIndex];
              if (bottleData != null) {
                final bottle = WineBottle.fromJson(bottleData);
                // Only add to grid if not marked as drunk
                if (!bottle.isDrunk) {
                  grid[i][j] = bottle;
                }
              }
              dataIndex++;
            }
          }
        }

        // Load drunk wines
        drunkWines.clear(); // Clear existing drunk wines before loading
        if (drunkData != null) {
          final List<dynamic> decodedDrunkData = json.decode(drunkData);
          for (var wineData in decodedDrunkData) {
            final bottle = WineBottle.fromJson(wineData);
            // Only add to drunk wines if actually marked as drunk
            if (bottle.isDrunk && bottle.dateDrunk != null) {
              drunkWines.add(bottle);
            }
          }
        }

        _updateStatistics();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }



Future<void> _handleImageSelection(BuildContext context, WineBottle bottle) async {
  try {
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(
                    context,
                    await _picker.pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                      imageQuality: 85,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Library'),
                onTap: () async {
                  Navigator.pop(
                    context,
                    await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (image != null) {
      // Crop the selected image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4), // Vertical bottle aspect ratio
        compressQuality: 85,
        maxHeight: 1920,
        maxWidth: 1440,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Wine Photo',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.ratio3x2, // Changed from ratio3x4
            lockAspectRatio: true,
            hideBottomControls: false,
            statusBarColor: Theme.of(context).colorScheme.surface,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Wine Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          bottle.imagePath = croppedFile.path;
        });
      }
    }
  } catch (e) {
    _showErrorSnackBar('Could not access camera or photos');
  }
}
  void _updateStatistics() {
    int bottles = 0;
    for (var row in grid) {
      for (var bottle in row) {
        if (!bottle.isEmpty) {
          bottles++;
        }
      }
    }
    setState(() {
      totalBottles = bottles;
    });
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save grid data
      final List<Map<String, dynamic>> flatGrid = [];
      for (var row in grid) {
        for (var bottle in row) {
          flatGrid.add(bottle.toJson());
        }
      }
      await prefs.setString('wine_grid', json.encode(flatGrid));

      // Save drunk wines data
      final List<Map<String, dynamic>> drunkWinesData =
          drunkWines.map((bottle) => bottle.toJson()).toList();
      await prefs.setString('drunk_wines', json.encode(drunkWinesData));

      _updateStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to save data');
    }
  }

  Widget _buildBottleCard(WineBottle bottle,
      {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: bottle.isEmpty
                    ? Colors.grey[900]
                    : Theme.of(context).cardColor,
                border: Border.all(
                  color:
                      bottle.isEmpty ? Colors.grey[800]! : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bottle.imagePath != null)
                    Hero(
                      tag: 'wine_image_${bottle.imagePath}',
                      child: Image.file(
                        File(bottle.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (!bottle.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red[900]!.withOpacity(0.3),
                            Colors.red[400]!.withOpacity(0.1),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.liquor, // Changed from wine_bar to liquor
                            size: 24,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Rest of the code remains the same...
                  if (!bottle.isEmpty) ...[
                    // Type and rating badge
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bottle.type != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: switch (bottle.type!) {
                                    WineType.red => Colors.red[400],
                                    WineType.white => Colors.amber[400],
                                    WineType.sparkling => Colors.blue[400],
                                    WineType.rose => Colors.pink[300],
                                    WineType.dessert => Colors.orange[400],
                                  }
                                      ?.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bottle.type!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (bottle.rating != null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber[400],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                bottle.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Wine information overlay
                    // In the _buildBottleCard method, find the wine information overlay section and replace it with:
// Wine information overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black,
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bottle.name != null && bottle.name!.isNotEmpty)
                              Text(
                                bottle.name!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (bottle.year != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                bottle.year!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red[300],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Favorite indicator
                    if (bottle.isFavorite)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.red[400],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: // Replace your current AppBar actions with this:
          AppBar(
        title: Text(
          'MY WINES',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wine_bar, color: Colors.white),
            onPressed: _showDrunkWines,
          ),
          IconButton(
            icon: Icon(
              isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
                _animationController.reset();
                _animationController.forward();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _showShareOptions(context);
                  break;
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'help':
                  // Add help dialog if needed
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              '$totalBottles Bottles',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = null;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedFilter == null
                          ? Colors.red[400]?.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedFilter == null
                            ? Colors.red[400]!
                            : Colors.grey[700]!,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: _selectedFilter == null
                            ? Colors.red[400]
                            : Colors.grey[400],
                        fontWeight: _selectedFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...WineType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: WineTypeButton(
                      type: type,
                      isSelected: type == _selectedFilter,
                      onTap: () {
                        setState(() {
                          _selectedFilter =
                              type == _selectedFilter ? null : type;
                          _animationController.reset();
                          _animationController.forward();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: settings.columns,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: settings.rows * settings.columns,
                    itemBuilder: (context, index) {
                      final row = index ~/ settings.columns;
                      final col = index % settings.columns;
                      final bottle = grid[row][col];

                      if (_selectedFilter != null &&
                          !bottle.isEmpty &&
                          bottle.type != _selectedFilter) {
                        return const SizedBox.shrink();
                      }

                      return _buildBottleCard(
                        bottle,
                        onTap: () => bottle.isEmpty
                            ? _handleWineBottle(row, col)
                            : _showBottleDetails(bottle),
// In your onLongPress handler in the GridView.builder, replace the existing menu with:
                        onLongPress: () {
                          if (!bottle.isEmpty) {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('Edit Wine'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _handleWineBottle(row, col,
                                              isEdit: true);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.copy),
                                        title: const Text('Copy Wine'),
                                        onTap: () {
                                          setState(() {
                                            _copiedWine = WineBottle(
                                              name: bottle.name,
                                              year: bottle.year,
                                              notes: bottle.notes,
                                              type: bottle.type,
                                              rating: bottle.rating,
                                              isFavorite: bottle.isFavorite,
                                              imagePath: bottle.imagePath,
                                            );
                                            _hasCopiedWine = true;
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Wine copied. Long-press an empty slot to paste.'),
                                              backgroundColor:
                                                  Colors.green[700],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // In the long press menu within WineFridgeGridState, add this new ListTile before the Delete Wine option:

                                      ListTile(
                                        leading: const Icon(Icons.wine_bar),
                                        title: const Text('Drink Wine'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Drink Wine'),
                                                content: const Text(
                                                    'Mark this wine as drunk?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        // Mark the wine as drunk and set the date
                                                        bottle.isDrunk = true;
                                                        bottle.dateDrunk =
                                                            DateTime.now();
                                                        drunkWines.add(
                                                            bottle); // Add to drunk wines list
                                                        grid[row][col] =
                                                            WineBottle(); // Replace with empty bottle
                                                      });
                                                      _saveData(); // This will now save both grid and drunk wines
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: const Text(
                                                              'Wine marked as drunk'),
                                                          backgroundColor:
                                                              Colors.green[700],
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Drink'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),

                                      ListTile(
                                        leading: const Icon(Icons.delete,
                                            color: Colors.red),
                                        title: const Text('Delete Wine',
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Show confirmation dialog
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text('Delete Wine'),
                                                content: const Text(
                                                    'Are you sure you want to delete this wine?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        grid[row][col] =
                                                            WineBottle(); // Replace with empty bottle
                                                      });
                                                      _saveData();
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: const Text(
                                                              'Wine deleted'),
                                                          backgroundColor:
                                                              Colors.red[700],
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Delete',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else if (_hasCopiedWine) {
                            // Rest of your existing paste logic remains the same
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.paste),
                                        title: const Text('Paste Wine'),
                                        onTap: () {
                                          setState(() {
                                            if (_copiedWine != null) {
                                              grid[row][col] = WineBottle(
                                                name: _copiedWine!.name,
                                                year: _copiedWine!.year,
                                                notes: _copiedWine!.notes,
                                                type: _copiedWine!.type,
                                                rating: _copiedWine!.rating,
                                                isFavorite:
                                                    _copiedWine!.isFavorite,
                                                imagePath:
                                                    _copiedWine!.imagePath,
                                                dateAdded: DateTime.now(),
                                              );
                                            }
                                          });
                                          _saveData();
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Wine pasted successfully'),
                                              backgroundColor:
                                                  Colors.green[700],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.add),
                                        title: const Text('Add New Wine'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _handleWineBottle(row, col);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else {
                            _handleWineBottle(row, col);
                          }
                        },
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: settings.rows * settings.columns,
                    itemBuilder: (context, index) {
                      final row = index ~/ settings.columns;
                      final col = index % settings.columns;
                      final bottle = grid[row][col];

                      if (bottle.isEmpty ||
                          (_selectedFilter != null &&
                              bottle.type != _selectedFilter)) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 120,
                          child: _buildBottleCard(
                            bottle,
                            onTap: () => _showBottleDetails(bottle),
                            onLongPress: () =>
                                _handleWineBottle(row, col, isEdit: true),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

Future<void> _showBottleDetails(WineBottle bottle) async {
  if (bottle.isEmpty) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setBottomSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (bottle.imagePath != null)
                Hero(
                  tag: 'wine_image_${bottle.imagePath}',
                  child: Image.file(
                    File(bottle.imagePath!),
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
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
                                style: TextStyle(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bottle.type != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: switch (bottle.type!) {
                            WineType.red => Colors.red[400],
                            WineType.white => Colors.amber[400],
                            WineType.sparkling => Colors.blue[400],
                            WineType.rose => Colors.pink[300],
                            WineType.dessert => Colors.orange[400],
                          }?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          bottle.type!.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      bottle.name ?? '',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bottle.year != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        bottle.year!,
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < (bottle.rating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setBottomSheetState(() {
                                  if (bottle.rating == index + 1) {
                                    bottle.rating = null;
                                  } else {
                                    bottle.rating = index + 1.0;
                                  }
                                });
                                setState(() {}); // Update parent state
                                _saveData();
                              },
                            );
                          }),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            bottle.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: bottle.isFavorite ? Colors.red[400] : Colors.white70,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setBottomSheetState(() {
                              bottle.isFavorite = !bottle.isFavorite;
                            });
                            setState(() {}); // Update parent state
                            _saveData();
                          },
                        ),
                      ],
                    ),
                    if (bottle.notes != null && bottle.notes!.isNotEmpty) ...[
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
                        bottle.notes!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          int row = -1, col = -1;
                          for (int i = 0; i < grid.length; i++) {
                            for (int j = 0; j < grid[i].length; j++) {
                              if (grid[i][j] == bottle) {
                                row = i;
                                col = j;
                                break;
                              }
                            }
                          }
                          if (row != -1 && col != -1) {
                            _handleWineBottle(row, col, isEdit: true);
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Wine'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          minimumSize: const Size(0, 56),
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
  void _shareWineList() {
    try {
      // Collect active bottles
      List<WineBottle> bottles = [];
      for (var row in grid) {
        for (var bottle in row) {
          if (!bottle.isEmpty) {
            bottles.add(bottle);
          }
        }
      }

      StringBuffer shareText = StringBuffer();

      // Simple header
      shareText.writeln('🍷 My Wine Collection');
      shareText.writeln('Total: ${bottles.length} bottles\n');

      // Group by wine type
      Map<WineType?, List<WineBottle>> groupedBottles = {};
      for (var bottle in bottles) {
        if (!groupedBottles.containsKey(bottle.type)) {
          groupedBottles[bottle.type] = [];
        }
        groupedBottles[bottle.type]!.add(bottle);
      }

      // Add bottles by type
      groupedBottles.forEach((type, typeBottles) {
        // Section header with emoji
        shareText.writeln(
            '${_getWineTypeEmoji(type)} ${type?.name.toUpperCase() ?? 'OTHER'}');

        // Sort bottles by name
        typeBottles.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

        // List bottles with minimal details
        for (var bottle in typeBottles) {
          if (bottle.isFavorite) shareText.write('⭐ ');
          shareText.write(bottle.name ?? 'Unnamed Wine');

          // Add year and rating in parentheses if available
          List<String> details = [];
          if (bottle.year != null) details.add(bottle.year!);
          if (bottle.rating != null) {
            details.add('${bottle.rating!.toStringAsFixed(1)}★');
          }

          if (details.isNotEmpty) {
            shareText.write(' (${details.join(' • ')})');
          }

          shareText.writeln();
        }
        shareText.writeln(); // Space between categories
      });

      // Recently drunk section
      if (drunkWines.isNotEmpty) {
        var recentDrunk = List<WineBottle>.from(drunkWines)
          ..sort((a, b) => (b.dateDrunk ?? DateTime.now())
              .compareTo(a.dateDrunk ?? DateTime.now()))
          ..take(3); // Show only last 3 drunk wines

        shareText.writeln('🍾 Recently Enjoyed');
        for (var wine in recentDrunk) {
          shareText.write('• ${wine.name ?? 'Unnamed Wine'}');
          if (wine.year != null) shareText.write(' (${wine.year})');
          shareText.writeln();
        }
      }

      // Share the text
      Share.share(
        shareText.toString(),
        subject: 'My Wine Collection',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share wine list');
    }
  }

// Helper method to get emoji for wine type
  String _getWineTypeEmoji(WineType? type) {
    return switch (type) {
      WineType.red => '🍷',
      WineType.white => '🥂',
      WineType.sparkling => '🍾',
      WineType.rose => '🌹',
      WineType.dessert => '🍯',
      null => '🍷',
    };
  }

// Add a method to show share options
  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Share via Email'),
                onTap: () {
                  Navigator.pop(context);
                  _shareWineList();
                },
              ),
              ListTile(
                leading: const Icon(Icons
                    .share), // Using built-in share icon instead of WhatsApp image
                title: const Text('Share via Other Apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareWineList();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDrunkWines() {
    final sortedDrunkWines = List<WineBottle>.from(drunkWines)
      ..sort((a, b) => (b.dateDrunk ?? DateTime.now())
          .compareTo(a.dateDrunk ?? DateTime.now()));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Drunk Wines',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sortedDrunkWines.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No drunk wines yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: sortedDrunkWines.length,
                  itemBuilder: (context, index) {
                    final wine = sortedDrunkWines[index];
                    return Dismissible(
                      key: ObjectKey(wine),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          drunkWines.remove(wine);
                        });
                        _saveData(); // Save after removing the wine

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Wine removed from history'),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  drunkWines.add(wine);
                                  drunkWines.sort((a, b) =>
                                      (b.dateDrunk ?? DateTime.now()).compareTo(
                                          a.dateDrunk ?? DateTime.now()));
                                });
                                _saveData();
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(wine.name ?? 'Unnamed Wine'),
                          subtitle: Text(
                            '${wine.year != null ? "${wine.year!}\n" : ""}'
                            'Drunk on: ${DateFormat('MMMM d, y').format(wine.dateDrunk!)}',
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: switch (wine.type!) {
                                WineType.red => Colors.red[400],
                                WineType.white => Colors.amber[400],
                                WineType.sparkling => Colors.blue[400],
                                WineType.rose => Colors.pink[300],
                                WineType.dessert => Colors.orange[400],
                              }
                                  ?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.wine_bar,
                              color: switch (wine.type!) {
                                WineType.red => Colors.red[400],
                                WineType.white => Colors.amber[400],
                                WineType.sparkling => Colors.blue[400],
                                WineType.rose => Colors.pink[300],
                                WineType.dessert => Colors.orange[400],
                              },
                            ),
                          ),
                          trailing: wine.rating != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber[400], size: 16),
                                    const SizedBox(width: 4),
                                    Text(wine.rating!.toString()),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
