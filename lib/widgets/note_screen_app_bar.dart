import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/screens/notes/note_screen.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/utils/note_state.dart';
import 'package:makernote/utils/routes.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class NoteScreenAppBar extends HookWidget implements PreferredSizeWidget {
  const NoteScreenAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _backButtonPressed(BuildContext context, NoteModel noteModel) {
    if (beamerKey.currentState!.routerDelegate.beamBack()) {
      return;
    } else {
      final currentUserId =
          Provider.of<AccessibilityService>(context, listen: false)
              .currentUserId;
      if (currentUserId != noteModel.ownerId) {
        beamerKey.currentState?.routerDelegate.beamToNamed([
          Routes.sharedScreen,
          noteModel.ownerId,
          if (noteModel.parentId != null) noteModel.parentId!,
        ].join('/'));
      } else {
        beamerKey.currentState?.routerDelegate.beamToNamed([
          Routes.documentScreen,
          if (noteModel.parentId != null) noteModel.parentId!,
        ].join('/'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final noteStack = Provider.of<NoteModelStack>(context);
    final noteModel = noteStack.focusedNote ?? noteStack.template;
    final stateWrapper = Provider.of<NoteScreenStateWrapper?>(context);

    NoteScreenState state =
        stateWrapper?.state ?? NoteScreenState.viewingTemplate;

    debugPrint('building note screen app bar: \n'
        '\t note: ${noteModel.hashCode} \n'
        '\t noteStack: ${noteStack.hashCode} \n');

    return AppBar(
      leading: // back button
          BackButton(
        onPressed: () {
          _backButtonPressed(context, noteModel);
        },
      ),

      // title
      title: Row(
        children: [
          Text(
            noteModel.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          // space
          const SizedBox(width: 10),

          if (kDebugMode) ...[
            // note type chips
            Chip(
              label: Text(
                noteModel.noteType.toString().split('.').last,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // space
            const SizedBox(width: 10),
            // note state chip
            Chip(
              label: Text(
                state.toString().split('.').last,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),

      actions: [
        // state: viewing template
        if (state == NoteScreenState.viewingTemplate) ...[
          // create exercise note button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                builder: (context) {
                  return CreateNewNoteSheet(
                      noteService: noteService, noteModel: noteModel);
                },
              );
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('Start Exercise'),
          ),
        ],

        // // state: editing template
        // if (state == NoteScreenState.editingTemplate) ...[
        //   // hide explanation switch
        //   Wrap(
        //     crossAxisAlignment: WrapCrossAlignment.center,
        //     children: [
        //       const Text('Hide Explanation'),
        //       ChangeNotifierProvider.value(
        //         value: noteModel,
        //         builder: (context, child) {
        //           return Consumer<NoteModel>(
        //             builder: (context, note, child) {
        //               return Switch(
        //                 value: note.hideExplanation,
        //                 onChanged: (value) async {
        //                   await noteService.setHideExplanation(
        //                     note: note,
        //                     hideExplanation: value,
        //                   );
        //                   note.setHideExplanation(value);
        //                 },
        //               );
        //             },
        //           );
        //         },
        //       ),
        //     ],
        //   ),
        // ],

        // state: viewing exercise
        if (state == NoteScreenState.viewingExercise) ...[
          // mc result toggle
          IconButton(
            onPressed: () {
              final multiPanelController =
                  Provider.of<MultiPanelController>(context, listen: false);

              if (multiPanelController.isPanelOpen('mcResult')) {
                multiPanelController.closePanel('mcResult');
              } else {
                multiPanelController.openPanel('mcResult');
              }
            },
            icon: const Icon(Symbols.rule),
          ),
        ],

        // state: doing exercise
        if (state == NoteScreenState.doingExercise) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.success,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onSuccess,
            ),
            onPressed: () async {
              await noteService.setLock(
                note: noteModel,
                locked: true,
                lockedAt: Timestamp.now(),
              );
              noteModel.setLocked(true, lockedAt: Timestamp.now());

              // prompt a dialog to notify the user
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Exercise Submitted'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Submit Exercise'),
          ),
        ],

        // state: submitted exercise
        if (state == NoteScreenState.submittedExercise) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.danger,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onDanger,
            ),
            onPressed: () async {
              await noteService.setLock(
                note: noteModel,
                locked: false,
                lockedAt: null,
              );
              noteModel.setLocked(false, lockedAt: null);

              // prompt a dialog to notify the user
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Exercise Submission Cancelled'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Submission'),
          ),
        ],

        // state: pending exercise
        if (state == NoteScreenState.pendingExercise) ...[
          IconButton(
            onPressed: () async {
              final markingNote = await noteService.createOverlayNote(
                  noteStack.overlays.last, NoteType.marking);

              noteStack.onCreatedNewOverlay(markingNote);

              // prompt a dialog to notify the user
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Marking Started'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            icon: const Icon(Icons.edit),
          )
        ],

        // state: editing marking
        if (state == NoteScreenState.editingMarking) ...[
          // start marking button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.warning,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onWarning,
            ),
            onPressed:
                noteStack.getNoteByNoteType(NoteType.exercise)?.locked == true
                    ? () async {
                        final markingNote =
                            noteStack.getNoteByNoteType(NoteType.marking)!;
                        await noteService.setLock(
                          note: markingNote,
                          locked: true,
                          lockedAt: null,
                        );
                        markingNote.setLocked(true, lockedAt: null);
                        noteStack.focusOverlay(markingNote);

                        // prompt a dialog to notify the user
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Submission Locked'),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    : null,
            icon: const Icon(Icons.check),
            label: const Text('Lock Submission'),
          )
        ],

        // state: started marking
        if (state == NoteScreenState.startedMarking) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.success,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onSuccess,
            ),
            onPressed: () async {
              final markingNote =
                  noteStack.getNoteByNoteType(NoteType.marking)!;
              await noteService.setLock(
                note: markingNote,
                locked: true,
                lockedAt: Timestamp.now(),
              );
              markingNote.setLocked(true, lockedAt: Timestamp.now());
              noteStack.focusOverlay(markingNote);

              // prompt a dialog to notify the user
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Marking Finished'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Finish Marking'),
          ),
        ],

        // state: finished marking
        if (state == NoteScreenState.finishedMarking) ...[
          // cancel marking button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.danger,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onDanger,
            ),
            onPressed: () async {
              final markingNote =
                  noteStack.getNoteByNoteType(NoteType.marking)!;
              await noteService.setLock(
                note: markingNote,
                locked: false,
                lockedAt: null,
              );
              markingNote.setLocked(false, lockedAt: null);
              noteStack.focusOverlay(markingNote);

              // prompt a dialog to notify the user
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Marking Cancelled'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Marking'),
          )
        ],

        // more options menu button
        Consumer<MultiPanelController>(
          builder: (context, multiPanelController, child) {
            return PopupMenuButton(
              position: PopupMenuPosition.under,
              itemBuilder: (context) {
                return [
                  // performance overview button (only for owner)
                  if (noteStack.template.ownerId ==
                      Provider.of<AccessibilityService>(context, listen: false)
                          .currentUserId)
                    PopupMenuItem(
                      onTap: () {
                        // route to performance overview screen
                        beamerKey.currentState?.routerDelegate.beamToNamed(
                            '${Routes.overviewScreen}/${noteStack.template.id}');
                      },
                      child: const Row(
                        children: [
                          Icon(Symbols.overview),
                          SizedBox(width: 10),
                          Text('Overview'),
                        ],
                      ),
                    ),

                  if (<NoteScreenState>[
                    NoteScreenState.editingTemplate,
                    NoteScreenState.doingExercise,
                  ].contains(state))
                    // mc sheet button
                    PopupMenuItem(
                      onTap: () {
                        multiPanelController.openPanel('mcList');
                      },
                      child: ListenableBuilder(
                        listenable: multiPanelController,
                        builder: (context, child) {
                          return const Row(
                            children: [
                              Icon(Symbols.lists),
                              SizedBox(width: 10),
                              Text('MC Sheet'),
                            ],
                          );
                        },
                      ),
                    ),

                  // mc result button
                  if (state.index >= NoteScreenState.pendingExercise.index)
                    PopupMenuItem(
                      onTap: () {
                        multiPanelController.openPanel('mcResult');
                      },
                      child: ListenableBuilder(
                        listenable: multiPanelController,
                        builder: (context, child) {
                          return const Row(
                            children: [
                              Icon(Symbols.rule),
                              SizedBox(width: 10),
                              Text('MC Result'),
                            ],
                          );
                        },
                      ),
                    ),

                  if (<NoteScreenState>[
                    NoteScreenState.editingTemplate,
                    NoteScreenState.editingMarking,
                    NoteScreenState.startedMarking,
                    NoteScreenState.finishedMarking,
                  ].contains(state)) ...[
                    // responses from others button
                    PopupMenuItem(
                      onTap: () {
                        multiPanelController.openPanel('responseList');
                      },
                      child: ListenableBuilder(
                        listenable: multiPanelController,
                        builder: (context, child) {
                          return const Row(
                            children: [
                              Icon(Symbols.groups),
                              SizedBox(width: 10),
                              Text('Student Homework'),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  // explanation list button
                  PopupMenuItem(
                    onTap: () {
                      multiPanelController.openPanel('explanationList');
                    },
                    child: ListenableBuilder(
                      listenable: multiPanelController,
                      builder: (context, child) {
                        return const Row(
                          children: [
                            Icon(Symbols.help),
                            SizedBox(width: 10),
                            Text('Explanations'),
                          ],
                        );
                      },
                    ),
                  ),
                ];
              },
            );
          },
        ),
      ],
    );
  }
}

class CreateNewNoteSheet extends HookWidget {
  const CreateNewNoteSheet({
    super.key,
    required this.noteService,
    required this.noteModel,
  });

  final NoteService noteService;
  final NoteModel noteModel;

  @override
  Widget build(BuildContext context) {
    final isPendingState = useState(false);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Your answer will be saved as a new note.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            // space
            const SizedBox(height: 20),

            // confirm button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: isPendingState.value
                  ? null
                  : () async {
                      try {
                        isPendingState.value = true;
                        final newNote = await noteService.createOverlayNote(
                          noteModel,
                          NoteType.exercise,
                        );

                        beamerKey.currentState?.routerDelegate.beamToNamed(
                          '${Routes.noteScreen}/${newNote.id}/${newNote.ownerId}',
                        );
                      } catch (e) {
                        isPendingState.value = false;
                        debugPrint('Error creating overlay note: $e');
                      }
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
