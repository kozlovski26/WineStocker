import 'package:flutter/material.dart';
import '../managers/wine_manager.dart';
import '../../utils/share_helper.dart';  // Add this import

class ShareDialog extends StatelessWidget {
  final WineManager wineManager;

  const ShareDialog({
    super.key,
    required this.wineManager,
  });

  @override
  Widget build(BuildContext context) {
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
            leading: const Icon(Icons.mail_outline),
            title: const Text('Share via Email'),
            onTap: () {
              Navigator.pop(context);
              ShareHelper.shareWineList(wineManager);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share via Other Apps'),
            onTap: () {
              Navigator.pop(context);
              ShareHelper.shareWineList(wineManager);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}