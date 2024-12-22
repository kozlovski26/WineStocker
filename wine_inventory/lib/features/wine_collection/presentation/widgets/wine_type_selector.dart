import 'package:flutter/material.dart';
import '../../../../core/models/wine_type.dart';
import '../../utils/wine_type_helper.dart';

class WineTypeSelector extends StatelessWidget {
  final WineType? selectedType;
  final Function(WineType) onTypeSelected;

  const WineTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wine Type',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: WineType.values.map((type) {
              final isSelected = selectedType == type;
              final color = WineTypeHelper.getTypeColor(type);
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onTypeSelected(type),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? color : Colors.white24,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          WineTypeHelper.getTypeIcon(type),
                          color: isSelected ? color : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          WineTypeHelper.getTypeName(type),
                          style: TextStyle(
                            color: isSelected ? color : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}