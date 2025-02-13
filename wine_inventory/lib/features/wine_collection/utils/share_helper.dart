// lib/features/wine_collection/utils/share_helper.dart
import 'package:share_plus/share_plus.dart';
import 'package:wine_inventory/core/models/wine_type.dart';
import 'package:wine_inventory/features/wine_collection/domain/models/wine_bottle.dart';
import 'package:wine_inventory/features/wine_collection/presentation/managers/wine_manager.dart';
import 'wine_type_helper.dart';

class ShareHelper {
  static void shareWineList(WineManager wineManager) {
    try {
      final StringBuffer shareText = StringBuffer();
      
      // Header
      shareText.writeln('🍷 My Wine Collection');
      shareText.writeln('Total: ${wineManager.totalBottles} bottles\n');

      // Group by wine type
      final groupedBottles = _groupBottlesByType(wineManager);
      _addGroupedBottlesToShare(shareText, groupedBottles);

      // Recently drunk section
      if (wineManager.drunkWines.isNotEmpty) {
        _addRecentlyDrunkToShare(shareText, wineManager);
      }

      // Share the text
      Share.share(
        shareText.toString(),
        subject: 'My Wine Stocker Collection',
      );
    } catch (e) {
      print('Failed to share wine list: $e');
    }
  }

  static Map<WineType?, List<WineBottle>> _groupBottlesByType(
      WineManager wineManager) {
    final Map<WineType?, List<WineBottle>> groupedBottles = {};
    
    for (var row in wineManager.grid) {
      for (var bottle in row) {
        if (!bottle.isEmpty) {
          if (!groupedBottles.containsKey(bottle.type)) {
            groupedBottles[bottle.type] = [];
          }
          groupedBottles[bottle.type]!.add(bottle);
        }
      }
    }
    
    return groupedBottles;
  }

  static void _addGroupedBottlesToShare(
      StringBuffer shareText, Map<WineType?, List<WineBottle>> groupedBottles) {
    groupedBottles.forEach((type, typeBottles) {
      shareText.writeln(
          '${type}');

      typeBottles.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

      for (var bottle in typeBottles) {
        if (bottle.isFavorite) shareText.write('⭐ ');
        shareText.write(bottle.name ?? 'Unnamed Wine');

        final List<String> details = [];
        if (bottle.year != null) details.add(bottle.year!);
        if (bottle.rating != null) {
          details.add('${bottle.rating!.toStringAsFixed(1)}★');
        }

        if (details.isNotEmpty) {
          shareText.write(' (${details.join(' • ')})');
        }

        shareText.writeln();
      }
      shareText.writeln();
    });
  }

  static void _addRecentlyDrunkToShare(
      StringBuffer shareText, WineManager wineManager) {
    final recentDrunk = List<WineBottle>.from(wineManager.drunkWines)
      ..sort((a, b) =>
          (b.dateDrunk ?? DateTime.now())
              .compareTo(a.dateDrunk ?? DateTime.now()))
      ..take(3);

    shareText.writeln('🍾 Recently Enjoyed');
    for (var wine in recentDrunk) {
      shareText.write('• ${wine.name ?? 'Unnamed Wine'}');
      if (wine.year != null) shareText.write(' (${wine.year})');
      shareText.writeln();
    }
  }
}
