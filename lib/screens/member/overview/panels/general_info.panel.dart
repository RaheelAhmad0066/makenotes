import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/user.service.dart';
import 'package:makernote/utils/helpers/item.helper.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:provider/provider.dart';

class GeneralInfoPanel extends HookWidget {
  const GeneralInfoPanel({
    super.key,
    required this.noteModel,
  });
  final NoteModel noteModel;

  static const String panelName = 'info';

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiPanelController>(
      builder: (context, multiPanelController, child) {
        return Card(
          margin: multiPanelController.isPanelOpen(panelName)
              ? null
              : const EdgeInsets.all(0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: multiPanelController.isPanelOpen(panelName) ? 320 : 0,
              child: Visibility(
                visible: multiPanelController.isPanelOpen(panelName),
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: multiPanelController.isPanelOpen(panelName) ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FlexWithExtension.withSpacing(
                      spacing: 16,
                      direction: Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              direction: Axis.vertical,
                              spacing: 8,
                              children: [
                                Text('Name',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      noteModel.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),

                                    // edit note name
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await showItemRenameDialog(
                                            context: context, item: noteModel);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // close
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                multiPanelController.closePanel(panelName);
                              },
                            ),
                          ],
                        ),

                        // created by
                        Wrap(
                          direction: Axis.vertical,
                          spacing: 8,
                          children: [
                            Text('Created by',
                                style: Theme.of(context).textTheme.bodySmall),
                            FutureBuilder(
                              future:
                                  UserService().getUser(noteModel.createdBy),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(snapshot.error.toString()),
                                  );
                                } else {
                                  return Text(
                                    snapshot.data!.name ?? 'Unknown',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  );
                                }
                              },
                            ),
                          ],
                        ),

                        // created at
                        Wrap(
                          direction: Axis.vertical,
                          spacing: 8,
                          children: [
                            Text('Created at',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              DateFormat.yMd()
                                  .add_jm()
                                  .format(noteModel.createdAt.toDate()),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),

                        // last updated
                        Wrap(
                          direction: Axis.vertical,
                          spacing: 8,
                          children: [
                            Text('Last updated',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              DateFormat.yMd()
                                  .add_jm()
                                  .format(noteModel.updatedAt.toDate()),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
