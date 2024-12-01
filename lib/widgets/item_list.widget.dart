import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/helpers/item.helper.dart';
import 'package:makernote/utils/routes.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class ItemListWidget extends HookWidget {
  const ItemListWidget({super.key, required this.item});
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
    return Draggable(
      data: item,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
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
      ),
      childWhenDragging: ListTile(
        selected: true,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(item.name),
      ),
      child: DragTarget<ItemModel>(
        onAccept: (item) {
          debugPrint('Accepted ${item.name} on ${this.item.name}');
          if (this.item is NoteModel) {
            return;
          } else if (this.item is FolderModel) {
            service?.moveItem(item.id!, this.item.id!);
          }
        },
        builder: (context, candidateItems, rejectedItems) => ListTile(
          leading: item.isVisible
              ? Icon(
                  icon,
                  color: iconColor,
                )
              : Icon(
                  Icons.visibility_off,
                  color: iconColor.withOpacity(0.5),
                ),
          title: Text(item.name),
          onTap: () {
            if (item is FolderModel) {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed('${Routes.documentScreen}/${item.id}');
            } else if (item is NoteModel) {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed('${Routes.noteScreen}/${item.id}');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This item is not supported')));
            }
          },
          trailing: PopupMenuButton(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            itemBuilder: (context) => [
              // overview
              if (item is NoteModel)
                PopupMenuItem(
                  child: const ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    title: Text('Overview'),
                    leading: Icon(Symbols.overview),
                  ),
                  onTap: () {
                    beamerKey.currentState?.routerDelegate
                        .beamToNamed('${Routes.overviewScreen}/${item.id}');
                  },
                ),

              // rename
              PopupMenuItem(
                child: const ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  title: Text('Rename'),
                  leading: Icon(Symbols.edit),
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      showItemRenameDialog(context: context, item: item);
                    },
                  );
                },
              ),

              // share
              PopupMenuItem(
                child: const ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  title: Text('Share'),
                  leading: Icon(Symbols.share),
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      showItemSharingDialog(
                        context: context,
                        title:
                            'Share ${item.type.toString().split('.').last}: ${item.name}',
                        itemId: item.id!,
                      );
                    },
                  );
                },
              ),

              // toggle visibility
              PopupMenuItem(
                child: ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  title:
                      Text(item.isVisible ? 'Hide in share' : 'Show in share'),
                  leading: Icon(item.isVisible
                      ? Symbols.visibility_off
                      : Symbols.visibility),
                ),
                onTap: () {
                  if (service == null) {
                    return;
                  }
                  service.setVisibility(item.id!, !item.isVisible);
                },
              ),

              // delete
              PopupMenuItem(
                child: ListTile(
                  iconColor:
                      Theme.of(context).extension<CustomColors>()?.danger,
                  textColor:
                      Theme.of(context).extension<CustomColors>()?.danger,
                  mouseCursor: SystemMouseCursors.click,
                  title: const Text('Move to trash'),
                  leading: const Icon(Symbols.delete),
                ),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Move to trash'),
                            content: const Text(
                                'Are you sure you want to move this folder to trash?'),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (service == null) {
                                    return;
                                  }
                                  service.moveToTrash(item.id!);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Move',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.danger),
                                ),
                              )
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
            icon: const Icon(Icons.more_vert),
            splashRadius: 20,
          ),
        ),
      ),
    );
  }
}

/*
Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: (candidateItems.isNotEmpty && item is FolderModel)
                ? BorderSide(
                    color:
                        Theme.of(context).extension<CustomColors>()?.dimmed ??
                            Colors.grey,
                  )
                : const BorderSide(color: Colors.transparent),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (item is FolderModel) {
                beamerKey.currentState?.routerDelegate
                    .beamToNamed('${Routes.documentScreen}/${item.id}');
              } else if (item is NoteModel) {
                beamerKey.currentState?.routerDelegate
                    .beamToNamed('${Routes.noteScreen}/${item.id}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('This item is not supported')));
              }
            },
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
                  right: 0,
                  top: 0,
                  child: PopupMenuButton(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    itemBuilder: (context) => [
                      // overview
                      if (item is NoteModel)
                        PopupMenuItem(
                          child: const ListTile(
                            mouseCursor: SystemMouseCursors.click,
                            title: Text('Overview'),
                            leading: Icon(Symbols.overview),
                          ),
                          onTap: () {
                            beamerKey.currentState?.routerDelegate.beamToNamed(
                                '${Routes.overviewScreen}/${item.id}');
                          },
                        ),

                      // rename
                      PopupMenuItem(
                        child: const ListTile(
                          mouseCursor: SystemMouseCursors.click,
                          title: Text('Rename'),
                          leading: Icon(Symbols.edit),
                        ),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) {
                              showItemRenameDialog(
                                  context: context, item: item);
                            },
                          );
                        },
                      ),

                      // share
                      PopupMenuItem(
                        child: const ListTile(
                          mouseCursor: SystemMouseCursors.click,
                          title: Text('Share'),
                          leading: Icon(Symbols.share),
                        ),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) {
                              showItemSharingDialog(
                                context: context,
                                title:
                                    'Share ${item.type.toString().split('.').last}: ${item.name}',
                                itemId: item.id!,
                              );
                            },
                          );
                        },
                      ),

                      // toggle visibility
                      PopupMenuItem(
                        child: ListTile(
                          mouseCursor: SystemMouseCursors.click,
                          title: Text(item.isVisible
                              ? 'Hide in share'
                              : 'Show in share'),
                          leading: Icon(item.isVisible
                              ? Symbols.visibility_off
                              : Symbols.visibility),
                        ),
                        onTap: () {
                          if (service == null) {
                            return;
                          }
                          service.setVisibility(item.id!, !item.isVisible);
                        },
                      ),

                      // delete
                      PopupMenuItem(
                        child: ListTile(
                          iconColor: Theme.of(context)
                              .extension<CustomColors>()
                              ?.danger,
                          textColor: Theme.of(context)
                              .extension<CustomColors>()
                              ?.danger,
                          mouseCursor: SystemMouseCursors.click,
                          title: const Text('Move to trash'),
                          leading: const Icon(Symbols.delete),
                        ),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Move to trash'),
                                    content: const Text(
                                        'Are you sure you want to move this folder to trash?'),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          if (service == null) {
                                            return;
                                          }
                                          service.moveToTrash(item.id!);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Move',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .extension<CustomColors>()
                                                  ?.danger),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                    splashRadius: 20,
                  ),
                ),

                // indicator for visibility, only if item is not visible
                if (!item.isVisible)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Symbols.visibility_off,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
 */
