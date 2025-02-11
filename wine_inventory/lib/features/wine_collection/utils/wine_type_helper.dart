import 'package:flutter/material.dart';
import '../../../core/models/wine_type.dart';

class WineTypeHelper {
  static Color getTypeColor(WineType type) {
    switch (type) {
      case WineType.red:
        return Colors.red[400]!;
      case WineType.white:
        return Colors.amber[300]!;
      case WineType.sparkling:
        return Colors.blue[300]!;
      case WineType.rose:
        return Colors.pink[300]!;
      case WineType.dessert:
        return Colors.orange[300]!;
      default:
        return Colors.grey[400]!;
    }
  }

  static String getTypeName(WineType type) {
    switch (type) {
      case WineType.red:
        return 'Red';
      case WineType.white:
        return 'White';
      case WineType.sparkling:
        return 'Sparkling';
      case WineType.rose:
        return 'Rosé';
      case WineType.dessert:
        return 'Dessert';
      default:
        return 'Unknown';
    }
  }

  static IconData getTypeIcon(WineType type) {
    switch (type) {
      case WineType.red:
        return Icons.wine_bar;
      case WineType.white:
        return Icons.wine_bar;
      case WineType.sparkling:
        return Icons.local_bar;
      case WineType.rose:
        return Icons.wine_bar;
      case WineType.dessert:
        return Icons.wine_bar;
      default:
        return Icons.wine_bar;
    }
  }
}