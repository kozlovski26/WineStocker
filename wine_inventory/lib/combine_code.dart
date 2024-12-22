import 'dart:io';

void main() async {
  final directory = Directory('.');
  final outputFileName = 'combined_code.txt';

  final outputFile = File(outputFileName);
  if (await outputFile.exists()) {
    await outputFile.delete();
  }
  await outputFile.create();

  await for (var entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && _isCodeFile(entity)) {
      final relativePath = entity.path;
      final fileContent = await entity.readAsString();
      await outputFile.writeAsString('''
--- Start of File: $relativePath ---
$fileContent
--- End of File: $relativePath ---
''', mode: FileMode.append);
    }
  }

  print('All code has been combined into $outputFileName');
}

bool _isCodeFile(File file) {
  final extensions = ['.dart', '.yaml', '.json', '.html', '.css', '.js'];
  final fileExtension = file.path.split('.').last;
  return extensions.contains('.$fileExtension');
}
