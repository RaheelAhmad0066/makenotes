import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/inspecting_user.wrapper.dart';
import 'package:makernote/models/note.wrapper.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:makernote/widgets/response_list.dart';
import 'package:provider/provider.dart';

class ResponsePanel extends HookWidget {
  const ResponsePanel({
    super.key,
    required this.noteId,
  });

  final String noteId;

  static const String panelName = 'response';

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final getAllUserNotesStream = useMemoized(
      () => noteService
          .getOverlayNotesStream(noteId: noteId, type: NoteType.exercise)
          .asBroadcastStream(),
      [noteId],
    );
    useEffect(() {
      var subscription = getAllUserNotesStream.listen((event) {
        debugPrint('Got user notes: $event');

        if (!context.mounted) return;

        var inspectingUserWrapper =
            Provider.of<InspectingUserWrapper>(context, listen: false);

        var inspectingNoteWrapper =
            Provider.of<NoteWrapper>(context, listen: false);

        if (inspectingUserWrapper.user != null) {
          // check if user is still in the list, if not, clear user
          if (!event.any(
              (note) => note.createdBy == inspectingUserWrapper.user?.uid)) {
            inspectingUserWrapper.user = null;
            inspectingNoteWrapper.note = null;
          } else if (inspectingUserWrapper.user != null &&
              inspectingNoteWrapper.note != null) {
            if (inspectingNoteWrapper.note?.createdBy !=
                inspectingUserWrapper.user?.uid) {
              inspectingNoteWrapper.note = event.firstWhere(
                  (note) => note.createdBy == inspectingUserWrapper.user?.uid);
            }
          }
        }
      });
      return () {
        getAllUserNotesStream.drain();
        subscription.cancel();
      };
    }, [
      getAllUserNotesStream,
    ]);
    return Consumer<MultiPanelController>(
      builder: (context, multiPanelController, children) {
        return GestureDetector(
          behavior:
              HitTestBehavior.opaque, // Ensures entire area is swipe-sensitive
          onHorizontalDragUpdate: (details) {
            // Detect swipe to the left (swipe distance threshold to prevent accidental swipes)
            if (details.delta.dx > 15) {
              // Adjust threshold as needed
              debugPrint("Swipe detected");
              multiPanelController.closePanel(panelName);
            }
          },
          child: Card(
            margin: multiPanelController.isPanelOpen(panelName)
                ? null
                : const EdgeInsets.all(0),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: multiPanelController.isPanelOpen(panelName) ? 360 : 0,
                child: Visibility(
                  visible: multiPanelController.isPanelOpen(panelName),
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AnimatedOpacity(
                    opacity:
                        multiPanelController.isPanelOpen(panelName) ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FlexWithExtension.withSpacing(
                        spacing: 16,
                        direction: Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // heading
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Student Homework',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),

                              // close
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  multiPanelController.closePanel(panelName);
                                },
                              ),
                            ],
                          ),

                          const Divider(),

                          Expanded(
                            child: StreamBuilder(
                              stream: getAllUserNotesStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: Text('No homework from student yet'),
                                  );
                                }

                                return Column(
                                  children: [
                                    // states
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // locked/total
                                        Text(
                                          '${snapshot.data?.where((note) => note.locked).length ?? 0}/${snapshot.data?.length ?? 0} submitted',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                              ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Expanded(
                                      child: UserResponseList(
                                        notes: snapshot.data ?? [],
                                        onUserTap: (user, note) {
                                          final inspectingUserWrapper = Provider
                                              .of<InspectingUserWrapper>(
                                                  context,
                                                  listen: false);
                                          final inspectingNoteWrapper =
                                              Provider.of<NoteWrapper>(context,
                                                  listen: false);

                                          if (inspectingUserWrapper.user?.uid ==
                                              user.uid) {
                                            inspectingUserWrapper.user = null;
                                            inspectingNoteWrapper.note = null;
                                          } else {
                                            inspectingUserWrapper.user = user;
                                            multiPanelController
                                                .openPanel('mcResult');

                                            inspectingNoteWrapper.note = note;
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
