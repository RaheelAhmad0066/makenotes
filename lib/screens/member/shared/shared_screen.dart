import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_list.wrapper.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:makernote/plugin/breadcrumb/breadcrumb.model.dart';
import 'package:makernote/plugin/breadcrumb/breadcrumb.wrapper.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/screens/member/shared/shared_location.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/services/item/shared.service.dart';
import 'package:makernote/utils/access_right.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/utils/view_mode.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:makernote/widgets/user_list_tile.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

class SharedHomeScreen extends HookWidget {
  const SharedHomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // screen title
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10, top: 20),
            child: Text(
              'Shared',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          const UserList(),
        ],
      ),
    );
  }
}

class SharedByUserScreen extends HookWidget {
  const SharedByUserScreen({
    super.key,
    required this.ownerId,
  });
  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final sharedService = Provider.of<SharedService>(context);
    final viewMode = useState<ViewMode>(ViewMode.grid);
    return FutureBuilder(
      future: sharedService.getOwnerInfo(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        final owner = snapshot.data as UserModel;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: owner),
          ],
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.only(
                top: 0,
                left: 20,
                right: 20,
                bottom: 0,
              ),
              child: FlexWithExtension.withSpacing(
                spacing: 20,
                direction: Axis.vertical,
                children: [
                  // screen title
                  Row(
                    children: [
                      Text(
                        'Shared by ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        owner.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // breadcrumb
                      Consumer<BreadcrumbWrapper>(
                        builder: (context, breadcrumbWrapper, child) {
                          return Row(
                            children:
                                breadcrumbWrapper.breadcrumbs.map((breadcrumb) {
                              return Row(
                                children: [
                                  Tooltip(
                                    message: breadcrumb.label,
                                    waitDuration:
                                        const Duration(milliseconds: 1000),
                                    child: TextButton(
                                      style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        breadcrumbWrapper
                                            .removeAfter(breadcrumb);
                                        beamerKey.currentState?.routerDelegate
                                            .beamToNamed(breadcrumb.route);
                                      },
                                      child: Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 140),
                                        child: Text(
                                          breadcrumb.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text('/'),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),

                      // view segment button
                      SegmentedButton<ViewMode>(
                        segments: const [
                          ButtonSegment<ViewMode>(
                            icon: Icon(Icons.list),
                            value: ViewMode.list,
                          ),
                          ButtonSegment<ViewMode>(
                            icon: Icon(Icons.grid_view),
                            value: ViewMode.grid,
                          ),
                        ],
                        selected: <ViewMode>{viewMode.value},
                        onSelectionChanged: (selected) {
                          viewMode.value = selected.first;
                        },
                      )
                    ],
                  ),

                  Expanded(
                    child: ClipRRect(
                      child: Beamer(
                        key: ValueKey(viewMode.hashCode),
                        routerDelegate: BeamerDelegate(
                          locationBuilder: (routeInformation, _) {
                            return SharedItemLocation(
                                routeInformation, ownerId, viewMode);
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SharedScreen extends HookWidget {
  const SharedScreen({
    super.key,
    required this.ownerId,
    required this.folderId,
    required this.viewMode,
  });
  final String ownerId;
  final String? folderId;
  final ValueNotifier<ViewMode> viewMode;

  @override
  Widget build(BuildContext context) {
    // show all folders shared by the user
    final sharedService = Provider.of<SharedService>(context);
    return FutureBuilder(
      future: sharedService.getOwnerInfo(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return ChangeNotifierProvider.value(
          value: snapshot.data,
          builder: (context, child) {
            return SingleChildScrollView(
              child: FutureBuilder(
                future: sharedService.getSharedItems(
                  ownerId: ownerId,
                  parentId: folderId,
                ),
                builder: (context, snapshot) {
                  debugPrint('build shared items');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final sharedItems =
                      snapshot.data?.where((element) => element.isVisible);

                  if (sharedItems?.isEmpty != false) {
                    return Text(
                      'No items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                    );
                  }

                  return FlexWithExtension.withSpacing(
                    spacing: 20,
                    direction: Axis.vertical,
                    children: [
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: ItemListWrapper(
                              items: sharedItems
                                      ?.where((element) =>
                                          element.type == ItemType.note &&
                                          (element as NoteModel).noteType ==
                                              NoteType.exercise &&
                                          element.createdBy ==
                                              sharedService.getUserId())
                                      .toList() ??
                                  [],
                            ),
                          ),
                        ],
                        builder: (context, snapshot) {
                          return FilteredItemList(
                            label: 'My Exercices',
                            icon: const Icon(
                              Symbols.exercise,
                            ),
                            viewMode: viewMode,
                          );
                        },
                      ),
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: ItemListWrapper(
                              items: sharedItems
                                      ?.where((element) =>
                                          element.type == ItemType.note &&
                                          (element as NoteModel).noteType ==
                                              NoteType.template)
                                      .toList() ??
                                  [],
                            ),
                          ),
                        ],
                        builder: (context, snapshot) {
                          return FilteredItemList(
                            label: 'Notes',
                            icon: const Icon(
                              Symbols.note,
                            ),
                            viewMode: viewMode,
                          );
                        },
                      ),
                      MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(
                            value: ItemListWrapper(
                              items: sharedItems
                                      ?.where((element) =>
                                          element.type == ItemType.folder &&
                                          snapshot.data!
                                              .where((e) => e is NoteModel
                                                  ? (e).overlayOn?.noteId ==
                                                      element.id
                                                  : false)
                                              .isEmpty)
                                      .toList() ??
                                  [],
                            ),
                          ),
                        ],
                        builder: (context, snapshot) {
                          return FilteredItemList(
                            label: 'Folders',
                            icon: const Icon(
                              Symbols.folder,
                            ),
                            viewMode: viewMode,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class FilteredItemList extends HookWidget {
  const FilteredItemList({
    super.key,
    required this.label,
    required this.viewMode,
    this.icon,
  });

  final ValueNotifier<ViewMode> viewMode;
  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemListWrapper>(
      builder: (context, itemListWrapper, child) {
        if (itemListWrapper.items.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // folders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  direction: Axis.horizontal,
                  spacing: 10,
                  children: [
                    if (icon != null) icon!,
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),

            const Divider(),

            Wrap(
              alignment: WrapAlignment.start,
              children: itemListWrapper.items
                  .map(
                    (item) => Tooltip(
                      message: item.name,
                      waitDuration: const Duration(milliseconds: 500),
                      child: viewMode.value == ViewMode.grid
                          ? ItemTile(
                              item: item,
                            )
                          : ItemListTile(
                              item: item,
                            ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class UserList extends HookWidget {
  const UserList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sharedService = Provider.of<SharedService>(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // search bar
          SearchAnchor.bar(
            barHintText: 'Search for users',
            barLeading: const Icon(Icons.search),
            barPadding: MaterialStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 15)),
            suggestionsBuilder: (context, controller) {
              final keyword = controller.text;
              return [
                FutureBuilder(
                  future: sharedService.getAccessibleOwners(keyword: keyword),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No data found'),
                      );
                    }

                    return ListView.builder(
                      cacheExtent: 0.0,
                      shrinkWrap: true,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return UserListTile(
                          contentPadding: const EdgeInsets.all(8),
                          user: snapshot.data![index],
                          onTap: () {
                            var user = snapshot.data![index];
                            final breadcrumbWrapper =
                                Provider.of<BreadcrumbWrapper>(context,
                                    listen: false);
                            breadcrumbWrapper.clear();
                            breadcrumbWrapper.addAll(
                              [
                                BreadcrumbModel(
                                  label: 'Shared',
                                  route: Routes.sharedScreen,
                                ),
                                BreadcrumbModel(
                                  label: 'Shared by ${user.name ?? 'Unknown'}',
                                  route: '${Routes.sharedScreen}/${user.uid}',
                                ),
                              ],
                            );
                            // redirect to [/shared/:ownerId]
                            beamerKey.currentState?.routerDelegate.beamToNamed(
                                '${Routes.sharedScreen}/${user.uid}');
                          },
                        );
                      },
                    );
                  },
                )
              ];
            },
          ),

          const SizedBox(height: 20),

          // title
          Text(
            'Shared with me',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const Divider(),

          FutureBuilder(
              future: sharedService.getAccessibleOwners(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No accessible users',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  );
                }

                return ListView.builder(
                  cacheExtent: 0.0,
                  shrinkWrap: true,
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    return UserListTile(
                      contentPadding: const EdgeInsets.all(8),
                      user: snapshot.data![index],
                      onTap: () {
                        var user = snapshot.data![index];
                        final breadcrumbWrapper =
                            Provider.of<BreadcrumbWrapper>(context,
                                listen: false);
                        breadcrumbWrapper.clear();
                        breadcrumbWrapper.addAll(
                          [
                            BreadcrumbModel(
                              label: 'Shared',
                              route: Routes.sharedScreen,
                            ),
                            BreadcrumbModel(
                              label: 'Shared by ${user.name ?? 'Unknown'}',
                              route: '${Routes.sharedScreen}/${user.uid}',
                            ),
                          ],
                        );
                        // redirect to [/shared/:ownerId]
                        beamerKey.currentState?.routerDelegate
                            .beamToNamed('${Routes.sharedScreen}/${user.uid}');
                      },
                    );
                  },
                );
              }),
        ],
      ),
    );
  }
}

class ItemTile extends HookWidget {
  const ItemTile({
    super.key,
    required this.item,
  });

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final IconData icon = (item is FolderModel)
        ? Symbols.folder
        : (item is NoteModel)
            ? ((item as NoteModel).overlayOn == null
                ? Symbols.note
                : Symbols.exercise)
            : Symbols.error;
    final Color iconColor = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (item.type == ItemType.note) {
            // add accessiblity for the user
            final accessibilityService =
                Provider.of<AccessibilityService>(context, listen: false);

            debugPrint("granting access");
            await accessibilityService.grantAccessRight(
              itemId: item.id!,
              ownerId: item.ownerId,
              rights: [AccessRight.read],
            );
            debugPrint("granted access");

            // redirect to [/note/:noteId/:ownerId]
            beamerKey.currentState?.routerDelegate
                .beamToNamed('${Routes.noteScreen}/${item.id}/${item.ownerId}');
          } else {
            // add breadcrumb
            final BreadcrumbWrapper breadcrumbWrapper =
                Provider.of<BreadcrumbWrapper>(context, listen: false);
            breadcrumbWrapper.add(
              BreadcrumbModel(
                label: item.name,
                route: '${Routes.sharedScreen}/${item.ownerId}/${item.id}',
              ),
            );

            // redirect to [/shared/:ownerId/:folderId]
            beamerKey.currentState?.routerDelegate.beamToNamed(
                '${Routes.sharedScreen}/${item.ownerId}/${item.id}');
          }
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 220),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((item is NoteModel) && (item as NoteModel).locked) ...[
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context)
                            .extension<CustomColors>()
                            ?.success,
                      ),
                      const SizedBox(width: 10),
                    ],

                    Icon(
                      icon,
                      color: iconColor,
                      size: 36,
                    ),

                    const SizedBox(width: 10),

                    // item name
                    Text(item.name),

                    const SizedBox(width: 10),
                  ],
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      // open item
                      const PopupMenuItem(
                        value: 'open',
                        child: ListTile(
                          mouseCursor: MouseCursor.defer,
                          leading: Icon(Icons.open_in_new),
                          title: Text('Open'),
                        ),
                      ),

                      // details
                      const PopupMenuItem(
                          value: 'details',
                          child: ListTile(
                            mouseCursor: MouseCursor.defer,
                            leading: Icon(Icons.info_outline),
                            title: Text('Details'),
                          )),

                      // delete item if it's an exercise note
                      if (item.type == ItemType.note &&
                          (item as NoteModel).noteType == NoteType.exercise &&
                          (item as NoteModel).createdBy ==
                              Provider.of<SharedService>(context, listen: false)
                                  .getUserId()) ...[
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            mouseCursor: MouseCursor.defer,
                            iconColor: Theme.of(context)
                                .extension<CustomColors>()
                                ?.danger,
                            textColor: Theme.of(context)
                                .extension<CustomColors>()
                                ?.danger,
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Delete'),
                          ),
                        ),
                      ],
                    ];
                  },
                  onSelected: (value) async {
                    if (value == 'open') {
                      // open item
                      if (item.type == ItemType.note) {
                        // add accessiblity for the user
                        final accessibilityService =
                            Provider.of<AccessibilityService>(context,
                                listen: false);

                        await accessibilityService.grantAccessRight(
                          itemId: item.id!,
                          ownerId: item.ownerId,
                          rights: [AccessRight.read],
                        );

                        // redirect to [/note/:noteId/:ownerId]
                        beamerKey.currentState?.routerDelegate.beamToNamed(
                            '${Routes.noteScreen}/${item.id}/${item.ownerId}');
                      } else {
                        // add breadcrumb
                        final BreadcrumbWrapper breadcrumbWrapper =
                            Provider.of<BreadcrumbWrapper>(context,
                                listen: false);
                        breadcrumbWrapper.add(
                          BreadcrumbModel(
                            label: item.name,
                            route:
                                '${Routes.sharedScreen}/${item.ownerId}/${item.id}',
                          ),
                        );

                        // redirect to [/shared/:ownerId/:folderId]
                        beamerKey.currentState?.routerDelegate.beamToNamed(
                            '${Routes.sharedScreen}/${item.ownerId}/${item.id}');
                      }
                    } else if (value == 'details') {
                      // show details dialog
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(item.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(item.id ?? ''),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item Type',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(item.type
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase()),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (item.type == ItemType.note) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Note Type',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      Text((item as NoteModel)
                                          .noteType
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase()),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Created at',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(DateFormat.yMd()
                                        .add_jm()
                                        .format(item.createdAt.toDate())),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Updated at',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(DateFormat.yMd()
                                        .add_jm()
                                        .format(item.updatedAt.toDate())),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (value == 'delete') {
                      // delete item
                      final noteService =
                          Provider.of<NoteService>(context, listen: false);
                      final showSnackBar =
                          ScaffoldMessenger.of(context).showSnackBar;
                      ItemListWrapper itemListWrapper =
                          Provider.of<ItemListWrapper>(context, listen: false);

                      try {
                        await showDialog(
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
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.danger,
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await noteService.deleteItem(
                                        itemId: item.id!,
                                        ownerId: item.ownerId,
                                      );
                                      itemListWrapper.deleteItem(item);
                                      showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Deleted "${item.name}"'),
                                        ),
                                      );
                                    },
                                    child: const Text('Delete')),
                              ],
                            );
                          },
                        );
                      } catch (e) {
                        debugPrint('Error deleting item: $e');
                        showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete ${item.name}'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ItemListTile extends HookWidget {
  const ItemListTile({
    super.key,
    required this.item,
  });
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.type == ItemType.folder ? Icons.folder : Icons.file_copy,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name),
            ],
          ),
        ],
      ),
      trailing: Text('Updated ${format(item.updatedAt.toDate())}'),
      onTap: () async {
        if (item.type == ItemType.note) {
          // add accessiblity for the user
          final accessibilityService =
              Provider.of<AccessibilityService>(context, listen: false);

          await accessibilityService.grantAccessRight(
            itemId: item.id!,
            ownerId: item.ownerId,
            rights: [AccessRight.read],
          );

          // redirect to [/note/:noteId/:ownerId]
          beamerKey.currentState?.routerDelegate
              .beamToNamed('${Routes.noteScreen}/${item.id}/${item.ownerId}');
        } else {
          // add breadcrumb
          final BreadcrumbWrapper breadcrumbWrapper =
              Provider.of<BreadcrumbWrapper>(context, listen: false);
          breadcrumbWrapper.add(
            BreadcrumbModel(
              label: item.name,
              route: '${Routes.sharedScreen}/${item.ownerId}/${item.id}',
            ),
          );

          // redirect to [/shared/:ownerId/:folderId]
          beamerKey.currentState?.routerDelegate
              .beamToNamed('${Routes.sharedScreen}/${item.ownerId}/${item.id}');
        }
      },
    );
  }
}
