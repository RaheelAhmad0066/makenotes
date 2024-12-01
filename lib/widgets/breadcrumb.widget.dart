import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:provider/provider.dart';

class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key, this.folderId, this.subfixItem});

  final String? subfixItem;
  final String? folderId;

  @override
  Widget build(BuildContext context) {
    FolderService folderService = Provider.of<FolderService>(context);
    return FutureBuilder(
      future: folderService.getParentItems(folderId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Once the data is loaded, display it
          List<ItemModel> items = snapshot.data!;
          // add the home button
          if (subfixItem != null) {
            items.insert(
              0,
              FolderModel(
                id: '',
                ownerId: folderService.getUserId()!,
                name: subfixItem!,
                createdAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
              ),
            );
          }

          if (items.isEmpty) {
            return const SizedBox.shrink();
          }

          return Row(
            children: items
                .map<Widget>((item) {
                  return Tooltip(
                    message: item.name,
                    waitDuration: const Duration(milliseconds: 1000),
                    child: DragTarget<ItemModel>(
                      onAccept: (dropItem) {
                        folderService.moveItem(dropItem.id!, item.id);
                      },
                      builder: (context, candidateItems, rejectedItems) =>
                          TextButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: (candidateItems.isNotEmpty)
                                  ? BorderSide(
                                      color: Theme.of(context)
                                              .extension<CustomColors>()
                                              ?.dimmed ??
                                          Colors.grey,
                                    )
                                  : const BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (items.last.id == item.id) {
                            return;
                          }
                          final paths = [
                            Routes.documentScreen,
                            if (item.id!.isNotEmpty) item.id
                          ];
                          beamerKey.currentState?.routerDelegate
                              .beamToNamed(paths.join('/'));
                        },
                        child: Row(
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (items.last.id == item.id)
                              const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  );
                })
                .expand((widget) => [widget, const Text(' / ')])
                .toList()
              ..removeLast(), // remove the last separator
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
