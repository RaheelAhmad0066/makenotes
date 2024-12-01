import 'package:flutter/material.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/widgets/dialogs/item_creation.dialog.dart';
import 'package:makernote/widgets/dialogs/item_rename.dialog.dart';
import 'package:makernote/widgets/dialogs/item_sharing.dialog.dart';
import 'package:makernote/widgets/dialogs/note_create_from_pdf.dialog.dart';

import '../../widgets/dialogs/copy_item_dialog.dart';

Future showItemRenameDialog({
  required BuildContext context,
  required ItemModel item,
}) {
  return showDialog(
    context: context,
    builder: (context) => ItemRenameDialog(
      item: item,
    ),
  );
}

Future<String?> showItemCreationDialog({
  required BuildContext context,
  required ItemType type,
  String? itemId,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => ItemCreationDialog(
      type: type,
      itemId: itemId,
    ),
  );
}

Future<String?> showItemCreateFromPDFDialog({
  required BuildContext context,
  String? folderId,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => NoteCreateFromPDFDialog(
      type: ItemType.note,
      folderId: folderId,
    ),
  );
}

Future showItemSharingDialog({
  required BuildContext context,
  required String itemId,
  String title = 'Share item',
}) {
  return showDialog(
    context: context,
    builder: (context) => ItemSharingDialog(
      itemId: itemId,
      title: title,
    ),
  );
}

Future showItemCopyDialog({
  required BuildContext context,
  required String itemId,
  String title = 'Copy item',
  // the async copy action
  Future<void> Function()? onCopy,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CopyItemDialog(
      title: title,
      onCopy: onCopy,
    ),
  );
}
