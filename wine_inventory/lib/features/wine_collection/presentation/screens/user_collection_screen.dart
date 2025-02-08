import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import '../widgets/wine_bottle_card.dart';
import '../widgets/wine_type_button.dart';
import '../../domain/models/wine_bottle.dart';
import '../../domain/models/grid_settings.dart';
import '../../data/repositories/wine_repository.dart';

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

    final screenWidth = MediaQuery.of(context).size.width;
    const maxVisibleColumns = 4;
    final cardWidth = _settings!.columns <= maxVisibleColumns 
        ? screenWidth / _settings!.columns 
        : screenWidth / maxVisibleColumns;
    const cardAspectRatio = 0.35;

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
            final bottle = _grid[row][col];

            if (_selectedFilter != null && 
                !bottle.isEmpty && 
                bottle.type != _selectedFilter) {
              return const SizedBox.shrink();
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
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _buildWineDetailsSheet(bottle),
    );
  }

  Widget _buildWineDetailsSheet(WineBottle bottle) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bottle.name ?? 'Unnamed Wine',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (bottle.year != null)
                Text(
                  'Year: ${bottle.year}',
                  style: const TextStyle(color: Colors.white70),
                ),
              if (bottle.price != null)
                Text(
                  'Price: ₪${bottle.price!.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              if (bottle.notes != null && bottle.notes!.isNotEmpty)
                Text(
                  'Notes: ${bottle.notes}',
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: bottle.isForTrade 
                      ? _initiateTrade 
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(
                    bottle.isForTrade 
                      ? 'Request Trade' 
                      : 'Not Available for Trade'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bottle.isForTrade 
                      ? Colors.green 
                      : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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