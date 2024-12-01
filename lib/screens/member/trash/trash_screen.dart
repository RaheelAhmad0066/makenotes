import 'package:flutter/material.dart';
import 'package:makernote/views/trash_view.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key, this.folderId});
  final String? folderId;

  @override
  Widget build(BuildContext context) {
    return const TrashView();
  }
}
