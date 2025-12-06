import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  final directory = Directory('assets/categoryIcons');
  final files = directory.listSync();

  final imageFiles =
      files
          .whereType<File>()
          .where(
            (file) =>
                file.path.toLowerCase().endsWith('.png') ||
                file.path.toLowerCase().endsWith('.jpg') ||
                file.path.toLowerCase().endsWith('.jpeg'),
          )
          .map((file) => 'assets/categoryIcons/${file.path.split('/').last}')
          .toList();

  final output = '''
// This file is auto-generated. Do not edit manually.
// Run: dart scripts/generate_assets_list.dart

const List<String> categoryIcons = $imageFiles;
''';

  await File('lib/src/constants/category_icons.dart').writeAsString(output);
  debugPrint('Generated ${imageFiles.length} icon paths');
  debugPrint('Output written to: lib/src/constants/category_icons.dart');
}
