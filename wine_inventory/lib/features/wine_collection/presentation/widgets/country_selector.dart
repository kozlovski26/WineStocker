import 'package:flutter/material.dart';
import '../../../../core/models/wine_country.dart';

class CountrySelector extends StatefulWidget {
  final String? selectedCountry;
  final Function(String) onCountrySelected;

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;
  List<WineCountry> _filteredCountries = WineCountry.topWineCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = WineCountry.topWineCountries.where((country) {
        return country.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _clearSelection() {
    widget.onCountrySelected(''); // Pass empty string to clear selection
    setState(() {
      _isOpen = false;
    });
  }

  Widget _buildSelectedCountry() {
    if (widget.selectedCountry == null || widget.selectedCountry!.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.search, color: Colors.white60, size: 20),
          const SizedBox(width: 8),
          Text(
            'Search or enter country...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    final flag = WineCountry.getFlagForCountry(widget.selectedCountry);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              flag ?? '🍷',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              widget.selectedCountry!,
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
          tooltip: 'Clear country',
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
          'Country',
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
                                    tooltip: 'Add custom country',
                                    onPressed: () {
                                      final customCountry = _searchController.text.trim();
                                      if (customCountry.isNotEmpty) {
                                        widget.onCountrySelected(customCountry);
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
                              widget.onCountrySelected(value);
                              _searchController.clear();
                              setState(() => _isOpen = false);
                              _focusNode.unfocus();
                            }
                          },
                        )
                      : _buildSelectedCountry(),
                ),
              ),
              if (_isOpen) ...[
                if (_filteredCountries.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        return InkWell(
                          onTap: () {
                            widget.onCountrySelected(country.name);
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
                                Text(country.flag, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  country.name,
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
                if (_searchController.text.isNotEmpty && _filteredCountries.isEmpty)
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