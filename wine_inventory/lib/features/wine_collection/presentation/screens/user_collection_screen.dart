import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/wine_bottle_card.dart';
import '../widgets/wine_type_button.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';
import 'package:wine_inventory/features/wine_collection/utils/wine_type_helper.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class UserCollectionScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserCollectionScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserCollectionScreen> createState() => _UserCollectionScreenState();
}

class _UserCollectionScreenState extends State<UserCollectionScreen>
    with SingleTickerProviderStateMixin {
  late WineRepository _repository;
  List<List<WineBottle>> _grid = [];
  bool _isLoading = true;
  GridSettings? _settings;
  WineType? _selectedFilter;
  int _totalBottles = 0;
  double _totalCollectionValue = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _repository = WineRepository(widget.userId);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserCollection();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCollection() async {
    try {
      setState(() => _isLoading = true);
      
      _settings = await _repository.loadGridSettings();
      _grid = await _repository.loadUserWineGrid(widget.userId, _settings!);
      
      _updateStatistics();
    } catch (e) {
      print('Error loading user collection: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateStatistics() {
    int bottles = 0;
    double total = 0;
    
    for (var row in _grid) {
      for (var bottle in row) {
        if (!bottle.isEmpty && 
            (_selectedFilter == null || bottle.type == _selectedFilter)) {
          bottles++;
          if (bottle.price != null) {
            total += bottle.price!;
          }
        }
      }
    }

    setState(() {
      _totalBottles = bottles;
      _totalCollectionValue = total;
    });
  }

  void _setFilter(WineType? type) {
    setState(() {
      _selectedFilter = (_selectedFilter == type) ? null : type;
      _updateStatistics();
    });
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                
                '${widget.userName}\'s wines',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                             fontSize: 20,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalBottles Bottles • ₪${_totalCollectionValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildFilterButtons(),
                  ),
                  Expanded(child: _buildWineGrid()),
                ],
              ),
      ),
    );
  }


  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildAllFilterButton(),
          const SizedBox(width: 8),
          ...WineType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WineTypeButton(
                type: type,
                isSelected: type == _selectedFilter,
                onTap: () => _setFilter(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFilterButton() {
    return GestureDetector(
      onTap: () => _setFilter(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildWineGrid() {
    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check if there are any bottles matching the current filter
    bool hasMatchingBottles = false;
    if (_selectedFilter != null) {
      for (var row in _grid) {
        for (var bottle in row) {
          if (!bottle.isEmpty && bottle.type == _selectedFilter) {
            hasMatchingBottles = true;
            break;
          }
        }
        if (hasMatchingBottles) break;
      }
    }

    // If no matching bottles, show message
    if (_selectedFilter != null && !hasMatchingBottles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.liquor_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${WineTypeHelper.getTypeName(_selectedFilter!)} wines in this collection',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const maxVisibleColumns = 4;
    final cardWidth = _settings!.columns <= maxVisibleColumns 
        ? screenWidth / _settings!.columns 
        : screenWidth / maxVisibleColumns;
    final cardAspectRatio = _settings!.cardAspectRatio ?? 0.57;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _settings!.columns <= maxVisibleColumns 
            ? screenWidth 
            : cardWidth * _settings!.columns,
        child: GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _settings!.columns,
            childAspectRatio: cardAspectRatio,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: _settings!.rows * _settings!.columns,
          itemBuilder: (context, index) {
            final row = index ~/ _settings!.columns;
            final col = index % _settings!.columns;
            
            if (row >= _grid.length || col >= _grid[row].length) {
              return const SizedBox.shrink();
            }

            final bottle = _grid[row][col];

            if (_selectedFilter != null && 
                (bottle.isEmpty || bottle.type != _selectedFilter)) {
              return Container(
                color: Colors.black12,
                child: Center(
                  child: Icon(
                    Icons.liquor_outlined,
                    color: Colors.grey[700],
                    size: 32,
                  ),
                ),
              );
            }

            return WineBottleCard(
              bottle: bottle,
              animation: _animation,
              onTap: () => _showWineDetails(bottle),
            );
          },
        ),
      ),
    );
  }

  void _showWineDetails(WineBottle bottle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (bottle.imagePath != null)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, bottle.imagePath!),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      child: _buildWineImage(bottle.imagePath!),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bottle.name ?? 'Unnamed Wine',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (bottle.type != null)
                        _buildDetailRow(
                          'Type',
                          WineTypeHelper.getTypeName(bottle.type!),
                        ),
                      if (bottle.year != null)
                        _buildDetailRow('Year', bottle.year.toString()),
                      if (bottle.price != null)
                        _buildDetailRow(
                          'Price',
                          '₪${bottle.price!.toStringAsFixed(2)}',
                        ),
                      if (bottle.notes?.isNotEmpty ?? false)
                        _buildDetailRow('Notes', bottle.notes!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildWineImage(imagePath),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWineImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.error_outline, size: 48, color: Colors.white54),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.error_outline, size: 48, color: Colors.white54),
        ),
      );
    }
  }

  void _initiateTrade() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trade request sent'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}