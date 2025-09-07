import 'dart:io';

void main() async {
  final inputFile = File('year_1404_grades.csv');
  final outputFile = File('correct_grades_1404.csv');

  if (!await inputFile.exists()) {
    print('Error: input file "year_1404_grades.csv" not found.');
    return;
  }

  final lines = await inputFile.readAsLines();
  final newLines = <String>[];

  // A map to hold the three values for each day/shift combination
  final Map<String, List<String>> dayShiftValues = {};

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    if (parts.length == 5) {
      final year = parts[0].trim();
      final month = parts[1].trim();
      final day = parts[2].trim();
      final shift = parts[3].trim();
      final value = parts[4].trim();
      final key = '$year,$month,$day,$shift';

      dayShiftValues.putIfAbsent(key, () => []).add(value);
    }
  }

  // Process the collected values
  dayShiftValues.forEach((key, values) {
    final parts = key.split(',');
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    final shift = parts[3];

    if (values.length == 3) {
      // Assuming the order is Tailing, Product, Feed based on previous logic
      newLines.add('$year,$month,$day,$shift,باطله,${values[0]}');
      newLines.add('$year,$month,$day,$shift,محصول,${values[1]}');
      newLines.add('$year,$month,$day,$shift,خوراک,${values[2]}');
    } else if (values.length == 2) {
      // Handle cases with only 2 values if necessary, maybe assign to product/feed
      newLines.add('$year,$month,$day,$shift,محصول,${values[0]}');
      newLines.add('$year,$month,$day,$shift,خوراک,${values[1]}');
    } else if (values.length == 1) {
      // Handle cases with only 1 value
      newLines.add('$year,$month,$day,$shift,خوراک,${values[0]}');
    }
  });

  await outputFile.writeAsString(newLines.join('\n'));
  print('Conversion complete! New file created: "correct_grades_1404.csv"');
}
