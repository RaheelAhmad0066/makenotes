import 'package:flutter/material.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/services/item/folder_service.dart';
import 'package:makernote/widgets/trashed_item.widget.dart';
import 'package:provider/provider.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    var folderService = Provider.of<FolderService>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // view title
          Text(
            'Trash Bin',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder(
                future: folderService.getTrashBinId(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return StreamBuilder<List<ItemModel>>(
                      stream: folderService.getTrashedItemsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint("Error: ${snapshot.error}");
                          return Text("Error: ${snapshot.error}");
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data?.isEmpty ?? true) {
                          return Center(
                              child: Text('No items in trash bin',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .extension<CustomColors>()
                                          ?.dimmed)));
                        }
                        return Wrap(
                          runSpacing: 10,
                          spacing: 10,
                          children: snapshot.data
                                  ?.map(
                                    (e) => Tooltip(
                                      message: e.name,
                                      waitDuration:
                                          const Duration(milliseconds: 1000),
                                      child: TrashedItemWidget(item: e),
                                    ),
                                  )
                                  .toList() ??
                              [],
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
