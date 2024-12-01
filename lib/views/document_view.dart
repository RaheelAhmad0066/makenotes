import 'dart:async';
import 'package:flutter/material.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_list.wrapper.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/utils/helpers/item.helper.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/utils/view_mode.dart';
import 'package:makernote/widgets/breadcrumb.widget.dart';
import 'package:makernote/widgets/item.widget.dart';
import 'package:makernote/widgets/item_list.widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

enum SortOrder { nameAsc, nameDesc, dateAsc, dateDesc }

class DocumentView extends StatefulWidget {
  const DocumentView({super.key, this.folderId});
  final String? folderId;

  @override
  DocumentViewState createState() => DocumentViewState();
}

class DocumentViewState extends State<DocumentView> {
  final SearchController _searchController = SearchController();
  final _searchFormKey = GlobalKey<FormState>();
  late Future<String> _trashBinIdFuture;
  late FolderService folderService;
  SortOrder currentSortOrder = SortOrder.nameAsc;

  // Set to track new item IDs
  Set<String> newItemIds = {};

  @override
  void initState() {
    super.initState();
    folderService = Provider.of<FolderService>(context, listen: false);
    _trashBinIdFuture = folderService.getTrashBinId();
  }

  @override
  void dispose() {
    _searchController.clear();
    _searchController.dispose();
    folderService.clearData();
    super.dispose();
  }

  // Sort items based on current order
  List<ItemModel> _sortItems(List<ItemModel> items) {
    switch (currentSortOrder) {
      case SortOrder.nameAsc:
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOrder.nameDesc:
        items.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOrder.dateAsc:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.dateDesc:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // var folderService = Provider.of<FolderService>(context, listen: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Documents',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          _buildSearchBar(folderService),
          FutureBuilder(
            future: _trashBinIdFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Get trash bin error: ${snapshot.error}");
              }
              if (snapshot.hasData) {
                return _buildItemsStream(folderService);
              } else {
                return const Text("No data");
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FolderService folderService) {
    return Wrap(
      runSpacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: Form(
                key: _searchFormKey,
                child: SearchAnchor.bar(
                  suggestionsBuilder:
                      (BuildContext context, SearchController controller) {
                    return _buildSearchSuggestions(
                        folderService, controller.text);
                  },
                  searchController: _searchController,
                  barHintText: 'Search',
                  barPadding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 15)),
                  barLeading: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
        Row(
          children: [
            BreadcrumbWidget(
                subfixItem: 'My Documents', folderId: widget.folderId),
            const Spacer(),
            Consumer<ViewModeNotifier>(
              builder: (context, viewModeNotifier, child) {
                return SegmentedButton<ViewMode>(
                    segments: const [
                      ButtonSegment<ViewMode>(
                          icon: Icon(Icons.list), value: ViewMode.list),
                      ButtonSegment<ViewMode>(
                          icon: Icon(Icons.grid_view), value: ViewMode.grid),
                    ],
                    selected: <ViewMode>{
                      viewModeNotifier.viewMode
                    },
                    onSelectionChanged: (selected) {
                      newItemIds.clear();
                      viewModeNotifier.viewMode = selected.first;
                    });
              },
            )
          ],
        ),
      ],
    );
  }

  List<Widget> _buildSearchSuggestions(
      FolderService folderService, String keyword) {
    return [
      FutureBuilder(
        future: folderService.searchItemsByParentId(keyword,
            parentId: widget.folderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              final item = snapshot.data?[index];
              return ListTile(
                leading: item is FolderModel
                    ? const Icon(Symbols.folder)
                    : const Icon(Symbols.note),
                title: Text(item?.name ?? ''),
                onTap: () => _navigateToItem(item, context),
              );
            },
          );
        },
      ),
    ];
  }

  void _navigateToItem(ItemModel? item, BuildContext context) {
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
  }

  Widget _buildItemsStream(FolderService folderService) {
    return StreamBuilder<List<ItemModel>>(
      stream: folderService.getItemsStream(parentId: widget.folderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint("Get items error: ${snapshot.error}");
          return Text("Get items error: ${snapshot.error}");
        }
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemsSection(context, snapshot, ItemType.note, 'Notes',
                  Symbols.note, NoteType.template),
              const SizedBox(height: 20),
              _buildItemsSection(context, snapshot, ItemType.folder, 'Folders',
                  Symbols.folder, null),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsSection(
      BuildContext context,
      AsyncSnapshot<List<ItemModel>> snapshot,
      ItemType itemType,
      String title,
      IconData icon,
      NoteType? noteType) {
    var items = snapshot.data
            ?.where((item) =>
                item.type == itemType &&
                (noteType == null ||
                    (item is NoteModel && item.noteType == noteType)))
            .toList() ??
        [];

    // Sort items based on the selected sort order
    items = _sortItems(items);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ItemListWrapper(items: items)),
      ],
      child: Consumer<ItemListWrapper>(
        builder: (context, itemListWrapper, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  // _buildAddItemButton(context, itemType),
                  _buildAddAndFilterButtons(context, itemType),
                ],
              ),
              const Divider(),
              Consumer<ViewModeNotifier>(
                builder: (context, viewModeNotifier, child) {
                  return viewModeNotifier.viewMode == ViewMode.list
                      ? ListView.builder(
                          cacheExtent: 0.0,
                          shrinkWrap: true,
                          itemCount: itemListWrapper.items.length,
                          itemBuilder: (context, index) => Tooltip(
                            message: itemListWrapper.items[index].name,
                            waitDuration: const Duration(milliseconds: 300),
                            child: ItemListWidget(
                              item: itemListWrapper.items[index],
                            ),
                          ),
                        )
                      : Wrap(
                          runSpacing: 10,
                          spacing: 10,
                          children: itemListWrapper.items
                              .map(
                                (item) => Tooltip(
                                  message: item.name,
                                  waitDuration:
                                      const Duration(milliseconds: 1000),
                                  child: ItemWidget(
                                    item: item,
                                    isNew: newItemIds.contains(item.id),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddAndFilterButtons(BuildContext context, ItemType itemType) {
    return Row(
      children: [
        _buildAddItemButton(context, itemType),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildFilterButton() {
    return PopupMenuButton<SortOrder>(
      icon: const Icon(Icons.filter_list),
      onSelected: (selectedOrder) {
        setState(() {
          newItemIds.clear();
          currentSortOrder = selectedOrder;
        });
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: SortOrder.nameAsc,
            child: const Text('Sort by Name (A-Z)'),
          ),
          PopupMenuItem(
            value: SortOrder.nameDesc,
            child: const Text('Sort by Name (Z-A)'),
          ),
          PopupMenuItem(
            value: SortOrder.dateAsc,
            child: const Text('Sort by Date (Oldest First)'),
          ),
          PopupMenuItem(
            value: SortOrder.dateDesc,
            child: const Text('Sort by Date (Newest First)'),
          ),
        ];
      },
    );
  }

  Widget _buildAddItemButton(BuildContext context, ItemType itemType) {
    if (itemType == ItemType.folder) {
      return IconButton(
        onPressed: () async {
          var newItemId = await showItemCreationDialog(
            context: context,
            type: ItemType.folder,
            itemId: widget.folderId,
          );
          if (newItemId != null) {
            setState(() {
              newItemIds.clear();
              newItemIds.add(newItemId);
            });
          }
        },
        icon: Tooltip(
          message: 'Add Folder',
          child: const Icon(
            Icons.add,
          ),
        ),
      );
    }
    return PopupMenuButton(
      icon: Tooltip(message: "Add Note", child: const Icon(Icons.add)),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                var newItemId = await showItemCreationDialog(
                  context: context,
                  type: itemType,
                  itemId: widget.folderId,
                );
                if (newItemId != null) {
                  setState(() {
                    newItemIds.clear();
                    newItemIds.add(newItemId);
                  });
                }
              });
            },
            child: const Row(
              children: [
                Icon(Icons.note_add),
                SizedBox(width: 10),
                Text('Add empty note'),
              ],
            ),
          ),
          PopupMenuItem(
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                var newItemId = await showItemCreateFromPDFDialog(
                  context: context,
                  folderId: widget.folderId,
                );
                if (newItemId != null) {
                  setState(() {
                    newItemIds.clear();
                    newItemIds.add(newItemId);
                  });
                }
              });
            },
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf),
                SizedBox(width: 10),
                Text('Add from PDF'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
