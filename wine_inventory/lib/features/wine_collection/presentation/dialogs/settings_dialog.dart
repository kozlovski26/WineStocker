// lib/features/wine_collection/presentation/dialogs/settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/grid_settings.dart';
import '../managers/wine_manager.dart';
import '../../domain/models/wine_bottle.dart';

class SettingsDialog extends StatefulWidget {
  final WineManager wineManager;

  const SettingsDialog({
    super.key,
    required this.wineManager,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _rows;
  late int _columns;
  late double _aspectRatio;
  bool _isProcessing = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.wineManager.settings.rows;
    _columns = widget.wineManager.settings.columns;
    _aspectRatio = widget.wineManager.settings.cardAspectRatio ?? 0.57;
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    final isPro = await widget.wineManager.repository.isUserPro();
    if (mounted) {
      setState(() => _isPro = isPro);
    }
  }

  Future<bool> _checkForBottlesOutsideNewGrid(int newRows, int newColumns) async {
    final currentGrid = widget.wineManager.grid;
    bool hasBottlesOutside = false;

    for (int i = 0; i < currentGrid.length; i++) {
      for (int j = 0; j < currentGrid[i].length; j++) {
        if (!currentGrid[i][j].isEmpty && (i >= newRows || j >= newColumns)) {
          hasBottlesOutside = true;
          break;
        }
      }
      if (hasBottlesOutside) break;
    }

    return hasBottlesOutside;
  }

  Future<bool> _showWarningDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'Changing the grid size might affect bottles in your collection. '
            'Bottles outside the new grid size will be automatically moved to available spaces. '
            'Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[400],
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _handleGridSizeChange() async {
    // Only check for grid size changes if rows or columns are different
    final gridSizeChanged = _rows != widget.wineManager.settings.rows || 
                           _columns != widget.wineManager.settings.columns;
    
    if (gridSizeChanged) {
      final hasBottlesOutside = await _checkForBottlesOutsideNewGrid(_rows, _columns);
      if (hasBottlesOutside && !await _showWarningDialog(context)) {
        return;
      }
    }

    setState(() => _isProcessing = true);
    
    try {
      // Create new settings
      final newSettings = GridSettings(
        rows: _rows,
        columns: _columns,
        cardAspectRatio: await widget.wineManager.repository.isUserPro()
            ? _aspectRatio
            : widget.wineManager.settings.cardAspectRatio,
      );

      if (gridSizeChanged) {
        // Only reorganize bottles if grid size changed
        final List<WineBottle> bottles = [];
        final currentGrid = widget.wineManager.grid;
        
        for (int i = 0; i < currentGrid.length; i++) {
          for (int j = 0; j < currentGrid[i].length; j++) {
            if (!currentGrid[i][j].isEmpty) {
              bottles.add(currentGrid[i][j]);
            }
          }
        }

        // Create new grid with new dimensions
        List<List<WineBottle>> newGrid = List.generate(
          _rows,
          (i) => List.generate(_columns, (j) => WineBottle()),
        );

        // Place bottles in new grid
        int currentRow = 0;
        int currentCol = 0;

        for (var bottle in bottles) {
          while (currentRow < _rows) {
            if (currentCol >= _columns) {
              currentRow++;
              currentCol = 0;
              continue;
            }
            
            if (newGrid[currentRow][currentCol].isEmpty) {
              newGrid[currentRow][currentCol] = bottle;
              currentCol++;
              break;
            }
            
            currentCol++;
          }
        }

        // Save the reorganized grid
        await widget.wineManager.repository.saveWineGrid(newGrid);
      }

      // Save new settings
      await widget.wineManager.saveSettings(newSettings);
      await widget.wineManager.loadData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings updated successfully'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grid Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rows'),
                Text('($_rows)'),
              ],
            ),
            Slider(
              value: _rows.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: _rows.toString(),
              onChanged: (value) {
                setState(() => _rows = value.round());
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Columns'),
                Text('($_columns)'),
              ],
            ),
            Slider(
              value: _columns.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _columns.toString(),
              onChanged: (value) {
                setState(() => _columns = value.round());
              },
            ),
            if (_isPro) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Card Aspect Ratio'),
                  Text('(${_aspectRatio.toStringAsFixed(2)})'),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _aspectRatio,
                      min: 0.1,
                      max: 1.0,
                      divisions: 14,
                      label: _aspectRatio.toStringAsFixed(2),
                      onChanged: (value) {
                        setState(() => _aspectRatio = value);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _aspectRatio = 0.57);
                    },
                    icon: const Icon(Icons.restore),
                    tooltip: 'Reset to default (0.57)',
                  ),
                ],
              ),
              const Text(
                'Pro feature: Adjust the height/width ratio of wine cards',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total cells: ${_rows * _columns}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _handleGridSizeChange,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}