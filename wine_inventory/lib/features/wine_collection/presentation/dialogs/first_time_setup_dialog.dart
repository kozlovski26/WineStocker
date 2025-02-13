import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/grid_settings.dart';
import '../../domain/models/wine_bottle.dart';

class FirstTimeSetupDialog extends StatefulWidget {
  const FirstTimeSetupDialog({super.key});

  @override
  State<FirstTimeSetupDialog> createState() => _FirstTimeSetupDialogState();
}

class _FirstTimeSetupDialogState extends State<FirstTimeSetupDialog> {
  int rows = 4;
  int columns = 4;
  int _currentStep = 1; // Start directly with grid setup
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Design Your Wine\nFridge',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the dimensions that best match your collection.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            _buildSliders(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    minimumSize: const Size(120, 45),
                  ),
                  onPressed: _isProcessing ? null : () async {
                    setState(() => _isProcessing = true);
                    try {
                      final settings = GridSettings(
                        rows: rows,
                        columns: columns,
                        cardAspectRatio: 0.57,
                      );
                      
                      final List<List<WineBottle>> emptyGrid = List.generate(
                        rows,
                        (i) => List.generate(
                          columns,
                          (j) => WineBottle(),
                          growable: false,
                        ),
                        growable: false,
                      );
                      
                      if (mounted) {
                        Navigator.of(context).pop({
                          'settings': settings,
                          'grid': emptyGrid,
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating grid: ${e.toString()}'),
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
                  },
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.height, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              'Rows',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$rows',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red[400],
            inactiveTrackColor: Colors.red[900]?.withOpacity(0.3),
            thumbColor: Colors.red[400],
            overlayColor: Colors.red[400]?.withOpacity(0.1),
          ),
          child: Slider(
            value: rows.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (value) {
              setState(() => rows = value.round());
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.view_column, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              'Columns',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$columns',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red[400],
            inactiveTrackColor: Colors.red[900]?.withOpacity(0.3),
            thumbColor: Colors.red[400],
            overlayColor: Colors.red[400]?.withOpacity(0.1),
          ),
          child: Slider(
            value: columns.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() => columns = value.round());
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Total capacity: ${rows * columns} bottles',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (rows * columns > 100)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Large collections may affect performance',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
