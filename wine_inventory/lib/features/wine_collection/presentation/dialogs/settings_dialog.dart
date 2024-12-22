// lib/features/wine_collection/presentation/dialogs/settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/grid_settings.dart';
import '../managers/wine_manager.dart';

class SettingsDialog extends StatefulWidget {
  final WineManager wineManager;

  const SettingsDialog({
    super.key,
    required this.wineManager,
  });

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> {
  late int tempRows;
  late int tempColumns;

  @override
  void initState() {
    super.initState();
    tempRows = widget.wineManager.settings.rows;
    tempColumns = widget.wineManager.settings.columns;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Grid Settings',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Rows: $tempRows',
            style: const TextStyle(fontSize: 16),
          ),
          Slider(
            value: tempRows.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            onChanged: (value) {
              setState(() {
                tempRows = value.round();
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Columns: $tempColumns',
            style: const TextStyle(fontSize: 16),
          ),
          Slider(
            value: tempColumns.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            onChanged: (value) {
              setState(() {
                tempColumns = value.round();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final newSettings = GridSettings(
              rows: tempRows,
              columns: tempColumns,
            );
            await widget.wineManager.saveSettings(newSettings);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
