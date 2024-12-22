import 'package:flutter/material.dart';

class WineYearPicker extends StatelessWidget {
  final String? selectedYear;
  final ValueChanged<String?> onYearSelected;

  const WineYearPicker({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> years = List.generate(DateTime.now().year - 1950 + 1,
        (index) => (DateTime.now().year - index).toString());

    int initialYearIndex = years.indexOf(selectedYear ?? years[0]);
    if (initialYearIndex < 0) initialYearIndex = 0;

    return GestureDetector(
      onTap: () => _showYearPicker(context, years, initialYearIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedYear ?? 'Select Year',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _showYearPicker(
      BuildContext context, List<String> years, int initialYearIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        String currentSelectedYear = years[initialYearIndex];

        return StatefulBuilder(
          builder: (context, setState) => Container(
            height: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
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
                const SizedBox(height: 16),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: FixedExtentScrollController(
                      initialItem: initialYearIndex,
                    ),
                    itemExtent: 40,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        currentSelectedYear = years[index];
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: years.length,
                      builder: (context, index) {
                        final isSelected = years[index] == currentSelectedYear;
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            years[index],
                            style: TextStyle(
                              fontSize: 20,
                              color:
                                  isSelected ? Colors.red[400] : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      onYearSelected(currentSelectedYear); // Update the parent
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[400],
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
