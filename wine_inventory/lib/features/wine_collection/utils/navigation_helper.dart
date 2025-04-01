import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/managers/wine_manager.dart';
import '../presentation/screens/wine_scan_screen.dart';

/// Helper class for navigation between screens
/// Ensures proper Provider wrapping when needed
class NavigationHelper {
  
  /// Navigate to the wine scan screen with proper provider wrapping
  static Future<Map<String, dynamic>?> navigateToScanScreen(BuildContext context) async {
    // Create a new route that doesn't use Provider incorrectly
    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WineScanScreen(),
      ),
    );
  }
  
  /// Navigate to any screen with WineManager as a ChangeNotifierProvider
  static Future<T?> navigateWithWineManager<T>(
    BuildContext context, 
    Widget screen, 
    WineManager wineManager
  ) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: wineManager,
          child: screen,
        ),
      ),
    );
  }
} 