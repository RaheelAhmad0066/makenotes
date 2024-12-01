import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:provider/provider.dart';

class ItemRenameDialog extends HookWidget {
  ItemRenameDialog({
    super.key,
    required this.item,
  });

  final ItemModel item;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final ItemService? service = ((item is FolderModel)
        ? Provider.of<FolderService>(context, listen: false)
        : (item is NoteModel)
            ? Provider.of<NoteService>(context, listen: false)
            : null) as ItemService<ItemModel>?;
    final TextEditingController folderNameController =
        TextEditingController(text: item.name);
    return AlertDialog(
      title: Text('Rename ${item.type.toString().split('.').last}'),
      content: Form(
          child: TextFormField(
        controller: folderNameController,
        decoration: InputDecoration(hintText: '${item.type} name'),
      )),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).hintColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () async {
              if (service == null) {
                return;
              }
              service.renameItem(item.id!, folderNameController.value.text);
              Navigator.pop(context);
            },
            child: const Text('Update')),
      ],
    );
  }
}
