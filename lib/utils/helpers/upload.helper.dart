import 'package:flutter/material.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/widgets/dialogs/pick_file.dialog.dart';

Future<String?> showPickFileDialog({
  required BuildContext context,
  required FileType fileType,
  String? prefix,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => PickFileDialog(
      fileType: fileType,
      prefix: prefix,
      onSuccess: (url) => Navigator.pop(context, url),
    ),
  );
}
