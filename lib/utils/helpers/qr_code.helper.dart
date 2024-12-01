import 'package:flutter/material.dart';
import 'package:makernote/widgets/dialogs/scan_qr_code.dialog.dart';

Future<String?> showScanQRCodeDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return ScanQRCodeDialog(
        onScan: (code) {
          Navigator.of(context).pop(code);
        },
      );
    },
  );
}
