import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/inspecting_user.wrapper.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/services/user.service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/widgets/user_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

class ResponseList extends HookWidget {
  const ResponseList({
    super.key,
    required this.controllerKey,
    required this.controller,
    required this.noteId,
  });
  final String controllerKey;
  final MultiPanelController controller;
  final String noteId;

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final noteService = Provider.of<NoteService>(context);
    final getAllUserNotesStream = useMemoized(
      () => noteService
          .getOverlayNotesStream(noteId: noteId, type: NoteType.exercise)
          .asBroadcastStream(),
      [noteId],
    );
    useEffect(() {
      bool isMounted = true;
      var stream = getAllUserNotesStream.listen((event) {
        if (!context.mounted || !isMounted) return;
        if (!isMounted) return;
        debugPrint('Got user notes: $event');

        var inspectingUserWrapper =
            Provider.of<InspectingUserWrapper>(context, listen: false);

        if (inspectingUserWrapper.user != null) {
          // check if user is still in the list, if not, clear user
          if (!event.any(
              (note) => note.createdBy == inspectingUserWrapper.user?.uid)) {
            inspectingUserWrapper.clear();
          } else if (inspectingUserWrapper.user != null) {
            var noteStack = Provider.of<NoteModelStack>(context, listen: false);
            var drawingBoardController =
                Provider.of<DrawingBoardController>(context, listen: false);

            event
                .where(
                    (note) => note.createdBy == inspectingUserWrapper.user!.uid)
                .forEach((note) async {
              if (!isMounted) return;
              var userNoteStack =
                  await noteService.getNestedNotes(noteId: note.id!);

              debugPrint('User note stack: $userNoteStack');
              drawingBoardController.isHighlighting = true;
              noteStack.clearOverlays();
              noteStack.mergeStack(userNoteStack);
              noteStack.focusOverlayByCreator(noteService.getUserId()!);
            });
          }
        }
      });
      return () {
        stream.cancel();
        isMounted = false;
      };
    }, [
      getAllUserNotesStream,
    ]);

    // Initialize the debouncer
    final onUserTapDebouncer =
        useMemoized(() => Debouncer(milliseconds: 300), []);

    useEffect(() {
      return () {
        onUserTapDebouncer.dispose();
      };
    }, [onUserTapDebouncer]);

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque, // Ensures entire area is swipe-sensitive
      onHorizontalDragUpdate: (details) {
        // Detect swipe to the left (swipe distance threshold to prevent accidental swipes)
        if (details.delta.dx > 15) {
          // Negative dx for leftward swipe
          debugPrint("Swipe detected");
          controller.closePanel(controllerKey);
        }
      },
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.all(8),
                width: controller.isPanelOpen(controllerKey) ? 400 : 0,
                child: Visibility(
                  visible: controller.isPanelOpen(controllerKey),
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AnimatedOpacity(
                    opacity: controller.isPanelOpen(controllerKey) ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // header
                          Row(
                            children: [
                              // title
                              Expanded(
                                child: Text(
                                  'Student Homework',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),

                              // info dialog button
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(Icons.info,
                                                color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Marking Procedure'),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: Icon(
                                                  Icons.pending_actions,
                                                  color: Colors.orange),
                                              title: Text(
                                                  'Unsubmitted Student Homework'),
                                              subtitle: Text(
                                                  'Monitor and remind students to submit their homework.'),
                                            ),
                                            ListTile(
                                              leading: Icon(Icons.upload_file,
                                                  color: Colors.blue),
                                              title: Text(
                                                  'Submitted Student Homework'),
                                              subtitle: Text(
                                                  'Review all submitted homework before locking submissions.'),
                                            ),
                                            ListTile(
                                              leading: Icon(Icons.lock,
                                                  color: Colors.red),
                                              title: Text(
                                                  'Lock Submissions & Start Marking'),
                                              subtitle: Text(
                                                  'Prevent further submissions and begin the grading process.'),
                                            ),
                                            ListTile(
                                              leading: Icon(Icons.done_all,
                                                  color: Colors.green),
                                              title: Text(
                                                  'Finish Marking Homework'),
                                              subtitle: Text(
                                                  'Complete grading and provide feedback to students.'),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.info),
                              ),

                              // close button
                              IconButton(
                                onPressed: () {
                                  controller.closePanel(controllerKey);
                                },
                                icon: const Icon(Icons.close),
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
                                    child: Text('No home from student yet'),
                                  );
                                }

                                return Column(
                                  children: [
                                    // states
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // start marking all button
                                        ElevatedButton(
                                          onPressed: isLoading.value
                                              ? null
                                              : () async {
                                                  var noteService =
                                                      Provider.of<NoteService>(
                                                          context,
                                                          listen: false);
                                                  var noteStack = Provider.of<
                                                          NoteModelStack>(
                                                      context,
                                                      listen: false);

                                                  isLoading.value = true;
                                                  await noteService
                                                      .startMarkingAll(
                                                          templateNote:
                                                              noteStack
                                                                  .template);
                                                  isLoading.value = false;

                                                  // show dialog to notify user
                                                  if (context.mounted) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              'Success'),
                                                          content: const Text(
                                                              'All submissions are now locked'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'OK'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                          child: const Text(
                                              'Lock all submissions'),
                                        ),

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
                                        onUserTap: (user, note) async {
                                          onUserTapDebouncer.run(() async {
                                            var noteStack =
                                                Provider.of<NoteModelStack>(
                                                    context,
                                                    listen: false);

                                            var noteService =
                                                Provider.of<NoteService>(
                                                    context,
                                                    listen: false);

                                            var drawingBoardController =
                                                Provider.of<
                                                        DrawingBoardController>(
                                                    context,
                                                    listen: false);

                                            var inspectingUserWrapper = Provider
                                                .of<InspectingUserWrapper>(
                                                    context,
                                                    listen: false);

                                            if (inspectingUserWrapper
                                                        .user?.uid ==
                                                    user.uid &&
                                                inspectingUserWrapper.noteId ==
                                                    note.id) {
                                              // do nothing when the same user and note is tapped

                                              // debugPrint('Clearing user');
                                              // drawingBoardController.isHighlighting =
                                              //     false;
                                              // inspectingUserWrapper.clear();
                                              // noteStack.clearOverlays();
                                              // noteStack.focusTemplate();
                                              return;
                                            }

                                            try {
                                              var userNoteStack =
                                                  await noteService
                                                      .getNestedNotes(
                                                          noteId: note.id!);

                                              if (!context.mounted) return;

                                              noteStack.clearOverlays();

                                              // create a new overlay note if the last overlay is not a marking note
                                              if (!userNoteStack.hasNoteType(
                                                  NoteType.marking)) {
                                                debugPrint(
                                                    'creating new marking note');
                                                final markingNote = await noteService
                                                    .createOverlayNote(
                                                        userNoteStack
                                                            .overlays.last,
                                                        NoteType.marking);

                                                noteStack
                                                    .addOverlay(markingNote);
                                              }

                                              if (!context.mounted) return;

                                              debugPrint(
                                                  'User note stack: $userNoteStack');
                                              drawingBoardController
                                                  .isHighlighting = true;
                                              noteStack
                                                  .mergeStack(userNoteStack);
                                              noteStack.focusOverlayByCreator(
                                                  noteService.getUserId()!);

                                              inspectingUserWrapper.set(
                                                  user, note.id);
                                            } catch (e) {
                                              debugPrint(
                                                  'Error getting user note stack: $e');
                                            }
                                          });
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
          );
        },
      ),
    );
  }
}

class UserResponseList extends HookWidget {
  const UserResponseList({
    super.key,
    required this.notes,
    this.onUserTap,
  });
  final List<NoteModel> notes;

  final void Function(UserModel, NoteModel)? onUserTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 0.0,
      shrinkWrap: true,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return FutureProvider.value(
          value: Provider.of<UserService>(context, listen: false)
              .getUser(note.createdBy),
          initialData: null,
          builder: (context, child) {
            final user = Provider.of<UserModel?>(context);

            if (user == null) {
              return const SizedBox.shrink();
            }
            return Consumer<InspectingUserWrapper>(
              builder: (context, inspectingUserWrapper, child) {
                return Container(
                  color: user.uid == inspectingUserWrapper.user?.uid &&
                          note.id == inspectingUserWrapper.noteId
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  child: ListTile(
                    title: IgnorePointer(
                      ignoring: true,
                      child: UserListTile(
                        user: user,
                      ),
                    ),
                    trailing: !note.locked
                        ? Text(
                            format(note.updatedAt.toDate()),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Wrap(
                            direction: Axis.vertical,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 4,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context)
                                    .extension<CustomColors>()
                                    ?.success,
                              ),
                              Text(
                                format(note.lockedAt!.toDate()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                    onTap: () {
                      onUserTap?.call(user, note);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
