import 'package:flutter/material.dart';
import 'package:makernote/views/document_view.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key, this.folderId});
  final String? folderId;

  @override
  Widget build(BuildContext context) {
    return DocumentView(folderId: folderId);
  }
}
