import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List?> pickFile({List<String>? allowedExtensions}) async {
  var result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );

  if (result != null) {
    debugPrint('File picked: ${result.files.single.name}');

    if (kIsWeb) {
      return result.files.single.bytes;
    } else {
      // On mobile platforms, read the file bytes directly from the file path.
      final File file = File(result.files.single.path!);
      return await file.readAsBytes();
    }
  }

  debugPrint('No file selected');
  return null;
}
