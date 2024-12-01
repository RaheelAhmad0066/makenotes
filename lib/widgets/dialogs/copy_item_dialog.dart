import 'package:flutter/material.dart';

class CopyItemDialog extends StatefulWidget {
  final String title;
  final Future<void> Function()? onCopy;

  const CopyItemDialog({super.key, required this.title, this.onCopy});

  @override
  CopyItemDialogState createState() => CopyItemDialogState();
}

class CopyItemDialogState extends State<CopyItemDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: const Text('Do you want to copy this item?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  if (widget.onCopy != null) {
                    await widget.onCopy!();
                  }
                  if (context.mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop(true);
                  }
                },
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Copy'),
        ),
      ],
    );
  }
}
