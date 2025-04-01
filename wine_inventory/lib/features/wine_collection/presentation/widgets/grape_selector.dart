import 'package:flutter/material.dart';
import '../../../../core/models/wine_grape.dart';
import '../../../../core/models/wine_type.dart';

class GrapeSelector extends StatefulWidget {
  final String? selectedGrape;
  final Function(String) onGrapeSelected;
  final WineType? wineType;

  const GrapeSelector({
    super.key,
    required this.selectedGrape,
    required this.onGrapeSelected,
    this.wineType,
  });

  @override
  State<GrapeSelector> createState() => _GrapeSelectorState();
}

class _GrapeSelectorState extends State<GrapeSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;
  List<WineGrape> _filteredGrapes = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterGrapes);
    _updateGrapesList();
  }

  @override
  void didUpdateWidget(GrapeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wineType != widget.wineType) {
      _updateGrapesList();
    }
  }

  void _updateGrapesList() {
    if (widget.wineType == null) {
      _filteredGrapes = WineGrape.commonGrapes;
    } else {
      final type = widget.wineType == WineType.red ? 'red' : 'white';
      _filteredGrapes = WineGrape.getGrapesByType(type);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterGrapes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGrapes = WineGrape.commonGrapes
          .where((grape) => grape.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _clearSelection() {
    widget.onGrapeSelected('');
    setState(() {
      _isOpen = false;
    });
  }

  Widget _buildSelectedGrape() {
    if (widget.selectedGrape == null || widget.selectedGrape!.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.search, color: Colors.white60, size: 20),
          const SizedBox(width: 8),
          Text(
            'Search or enter grape variety...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.wine_bar,
              size: 16,
              color: widget.wineType == WineType.red ? Colors.red[400] : Colors.amber[400],
            ),
            const SizedBox(width: 8),
            Text(
              widget.selectedGrape!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: Colors.white60,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _clearSelection,
          tooltip: 'Clear grape variety',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grape Variety',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _isOpen = true);
                  _focusNode.requestFocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: _isOpen
                      ? TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    color: Colors.white60,
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Add custom grape variety',
                                    onPressed: () {
                                      final customGrape = _searchController.text.trim();
                                      if (customGrape.isNotEmpty) {
                                        widget.onGrapeSelected(customGrape);
                                        _searchController.clear();
                                        setState(() => _isOpen = false);
                                        _focusNode.unfocus();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    color: Colors.white60,
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _searchController.clear();
                                      _focusNode.requestFocus();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              widget.onGrapeSelected(value);
                              _searchController.clear();
                              setState(() => _isOpen = false);
                              _focusNode.unfocus();
                            }
                          },
                        )
                      : _buildSelectedGrape(),
                ),
              ),
              if (_isOpen) ...[
                if (_filteredGrapes.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredGrapes.length,
                      itemBuilder: (context, index) {
                        final grape = _filteredGrapes[index];
                        return InkWell(
                          onTap: () {
                            widget.onGrapeSelected(grape.name);
                            _searchController.clear();
                            setState(() => _isOpen = false);
                            _focusNode.unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wine_bar,
                                  size: 16,
                                  color: grape.type == 'red' ? Colors.red[400] : Colors.amber[400],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  grape.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_searchController.text.isNotEmpty && _filteredGrapes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white60, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Press Enter or + to add "${_searchController.text}"',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
} 






