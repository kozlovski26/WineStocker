import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/grid_settings.dart';

class FirstTimeSetupDialog extends StatefulWidget {
  const FirstTimeSetupDialog({super.key});

  @override
  State<FirstTimeSetupDialog> createState() => _FirstTimeSetupDialogState();
}

class _FirstTimeSetupDialogState extends State<FirstTimeSetupDialog> {
  int rows = 4;
  int columns = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Setup Your Wine Fridge',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose the size of your wine fridge grid.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rows: $rows',
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: rows.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      onChanged: (value) {
                        setState(() {
                          rows = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Columns: $columns',
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: columns.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      onChanged: (value) {
                        setState(() {
                          columns = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              GridSettings(rows: rows, columns: columns),
            );
          },
          child: const Text('Set Up'),
        ),
      ],
    );
  }
}
