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
    // Directly trigger the share functionality when the dialog is built
    // Use a short delay to allow the dialog to build before triggering the share
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      ShareHelper.shareWineList(wineManager);
    });

    // Return a minimal loading indicator that will be shown briefly
    return Container(
      height: 100,
      color: Colors.transparent,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}