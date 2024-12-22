import 'package:flutter/material.dart';
import '../../../../core/models/wine_type.dart';

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