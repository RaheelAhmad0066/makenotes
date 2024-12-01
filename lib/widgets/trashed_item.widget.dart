import 'package:flutter/material.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class TrashedItemWidget extends StatelessWidget {
  const TrashedItemWidget({super.key, required this.item});
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final ItemService? service = ((item is FolderModel)
        ? Provider.of<FolderService>(context, listen: false)
        : (item is NoteModel)
            ? Provider.of<NoteService>(context, listen: false)
            : null) as ItemService<ItemModel>?;
    final IconData icon = (item is FolderModel)
        ? Symbols.folder
        : (item is NoteModel)
            ? ((item as NoteModel).overlayOn == null
                ? Symbols.note
                : Symbols.exercise)
            : Symbols.error;
    final Color iconColor = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      shape: ShapeBorder.lerp(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          1)!,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 50,
                  color: iconColor,
                ),
                const SizedBox(
                  height: 4,
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    leading: Icon(Icons.restore),
                    title: Text('Restore'),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      service?.recoverFromTrash(item.id!);
                    });
                  },
                ),
                PopupMenuItem(
                  child: ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    iconColor:
                        Theme.of(context).extension<CustomColors>()?.danger,
                    textColor:
                        Theme.of(context).extension<CustomColors>()?.danger,
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                  ),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Deleting item'),
                              content: const Text(
                                  'This action cannot be undone. Are you sure?'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () async {
                                      service?.deleteItem(itemId: item.id!);
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .extension<CustomColors>()
                                              ?.danger),
                                    ))
                              ],
                            );
                          });
                    });
                  },
                ),
              ],
              icon: const Icon(Icons.more_vert),
              splashRadius: 20,
            ),
          )
        ],
      ),
    );
  }
}
