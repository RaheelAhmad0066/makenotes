import 'dart:async';
import 'package:flutter/material.dart';
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

class ItemWidget extends StatefulWidget {
  final ItemModel item;
  final bool isNew;

  const ItemWidget({super.key, required this.item, required this.isNew});

  @override
  ItemWidgetState createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget> {
  late bool isNew; // Changed to late

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    isNew = widget.isNew; // Initialize isNew here

    if (isNew) {
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            isNew = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.isNew) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemService? service = ((widget.item is FolderModel)
        ? Provider.of<FolderService>(context, listen: false)
        : (widget.item is NoteModel)
            ? Provider.of<NoteService>(context, listen: false)
            : null) as ItemService<ItemModel>?;

    final IconData icon = (widget.item is FolderModel)
        ? Symbols.folder
        : (widget.item is NoteModel &&
                (widget.item as NoteModel).overlayOn == null)
            ? Symbols.note
            : Symbols.exercise;

    final Color iconColor = Theme.of(context).colorScheme.primary;

    return Draggable(
      data: widget.item,
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
                  widget.item.name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Card(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                  widget.item.name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      child: DragTarget<ItemModel>(
        onAccept: (item) {
          debugPrint('Accepted ${item.name} on ${widget.item.name}');
          if (widget.item is NoteModel) {
            return;
          } else if (widget.item is FolderModel) {
            service?.moveItem(item.id!, widget.item.id!);
          }
        },
        builder: (context, candidateItems, rejectedItems) => Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isNew ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (widget.item is FolderModel) {
                beamerKey.currentState?.routerDelegate
                    .beamToNamed('${Routes.documentScreen}/${widget.item.id}');
              } else if (widget.item is NoteModel) {
                beamerKey.currentState?.routerDelegate
                    .beamToNamed('${Routes.noteScreen}/${widget.item.id}');
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
                          widget.item.name,
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
                      if (widget.item is NoteModel) ...[
                        PopupMenuItem(
                          child: const ListTile(
                            mouseCursor: SystemMouseCursors.click,
                            title: Text('Overview'),
                            leading: Icon(Symbols.overview),
                          ),
                          onTap: () {
                            beamerKey.currentState?.routerDelegate.beamToNamed(
                                '${Routes.overviewScreen}/${widget.item.id}');
                          },
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            mouseCursor: SystemMouseCursors.click,
                            title: Text('Copy'),
                            leading: Icon(Symbols.content_copy),
                          ),
                          onTap: () {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) async {
                                final toCopy = await showItemCopyDialog(
                                  context: context,
                                  itemId: widget.item.id!,
                                  title: 'Copy note',
                                  onCopy: () async {
                                    await service?.copyItem(widget.item.id!);
                                  },
                                );

                                if (toCopy == true && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Note copied'),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
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
                                  context: context, item: widget.item);
                            },
                          );
                        },
                      ),
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
                                    'Share ${widget.item.type.toString().split('.').last}: ${widget.item.name}',
                                itemId: widget.item.id!,
                              );
                            },
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          mouseCursor: SystemMouseCursors.click,
                          title: Text(widget.item.isVisible
                              ? 'Hide in share'
                              : 'Show in share'),
                          leading: Icon(widget.item.isVisible
                              ? Symbols.visibility_off
                              : Symbols.visibility),
                        ),
                        onTap: () {
                          if (service == null) {
                            return;
                          }
                          service.setVisibility(
                              widget.item.id!, !widget.item.isVisible);
                        },
                      ),
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
                                          service.moveToTrash(widget.item.id!);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Move',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .extension<CustomColors>()
                                                  ?.danger),
                                        ),
                                      ),
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
                if (!widget.item.isVisible)
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
        ),
      ),
    );
  }
}
