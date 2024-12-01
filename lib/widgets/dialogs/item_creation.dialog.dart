import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:provider/provider.dart';

class ItemCreationDialog extends HookWidget {
  const ItemCreationDialog({
    super.key,
    required this.type,
    this.itemId,
  });

  final ItemType type;
  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final createFormKey = useMemoized(() => GlobalKey<FormState>());
    final textEditingController = useTextEditingController();
    final errorMessage = useState<String?>(null);

    final isPending = useState(false);

    return AlertDialog(
      title: Text('Create a new ${type.toString().split('.').last}'),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: isPending.value
            ? Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 100,
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Form(
                key: createFormKey,
                child: TextFormField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    hintText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }

                    // Return the error message if it's not null
                    if (errorMessage.value != null) {
                      return errorMessage.value;
                    }

                    return null;
                  },
                ),
              ),
      ),
      actions: [
        // cancel button with neutral color
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).hintColor,
          ),
          onPressed: () {
            textEditingController.clear();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isPending.value
              ? null
              : () async {
                  if (createFormKey.currentState!.validate()) {
                    try {
                      isPending.value = true;
                      errorMessage.value = null; // Clear any previous errors

                      String newItemId;
                      if (type == ItemType.folder) {
                        final folderService =
                            Provider.of<FolderService>(context, listen: false);
                        newItemId = await folderService.addItem(
                            textEditingController.text,
                            parentId: itemId);
                      } else if (type == ItemType.note) {
                        final noteService =
                            Provider.of<NoteService>(context, listen: false);
                        newItemId = await noteService.addItem(
                            textEditingController.text,
                            parentId: itemId);
                      } else {
                        throw Exception('Invalid item type');
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${type.toString().split('.').last} created',
                            ),
                          ),
                        );
                        Navigator.pop(context, newItemId);
                      }
                    } catch (e) {
                      debugPrint('Error: $e');
                      errorMessage.value = e.toString();

                      createFormKey.currentState!.validate();

                      isPending.value = false;
                    }
                  }
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
