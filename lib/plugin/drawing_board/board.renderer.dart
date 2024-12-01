import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide InteractiveViewer, PanAxis;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/inspecting_user.wrapper.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:makernote/plugin/digit_recognition/draggable_widget.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_page_service.dart';
import 'package:makernote/plugin/drawing_board/services/note_stack_page.service.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command_driver.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/editor_hint.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/toolbar.dart';
import 'package:makernote/plugin/drawing_board/util/zoom_gesture.recognizer.dart';
import 'package:makernote/services/item/page.service.dart';
import 'package:makernote/services/user.service.dart';
import 'package:provider/provider.dart';

import '../../screens/notes/note_screen.dart';
import '../../services/item/graphic_element.service.dart';
import '../../services/item/note_service.dart';
import '../../utils/note_state.dart';
import 'controllers/drawing_board.controller.dart';
import 'graphic_elements/base_graphic_element.dart';
import 'models/graphic_element_model.dart';
import 'page.renderer.dart';
import 'util/saving_indicator.dart';
import 'util/widgets/custom_interactive_viewer.dart';
import 'util/widgets/drawing_controls.dart';
import 'util/widgets/editor_controls.dart';
import 'util/widgets/zoom_controls.dart';

class BoardRenderer extends HookWidget {
  const BoardRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    NoteModelStack noteStack = Provider.of<NoteModelStack>(context);
    PageService pageService = Provider.of<PageService>(context);

    final createEditorController = useCallback<
        EditorController? Function({
          PageModel? pageModel,
          required NoteModel focusedNote,
        })>(({
      PageModel? pageModel,
      required NoteModel focusedNote,
    }) {
      if (pageModel == null || focusedNote.lockedAt != null) {
        return null;
      } else {
        return EditorController(
          driver: CommandDriver(),
          pageModel: pageModel,
          editorPageService: EditorPageService(
            pageService: pageService,
            grahpicElementService:
                Provider.of<GraphicElementService>(context, listen: false),
            note: noteStack.focusedNote!,
            currentPage: pageModel,
          ),
        );
      }
    }, []);

    debugPrint('building board renderer');

    return Selector<DrawingBoardController, bool>(
      selector: (context, controller) => controller.isHighlighting,
      builder: (context, isHighlighting, child) {
        return Container(
          color: isHighlighting
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).highlightColor,
          child: Consumer<NoteStackPageService>(
            builder: (context, noteStackPageService, child) {
              if (!noteStackPageService.noteStack.hasFocus) {
                // no focus note for editing
                return BoardRendererLayout(
                  key: ValueKey(noteStackPageService.hashCode),
                );
              } else {
                // has focus note for editing
                return FutureBuilder(
                  future: noteStackPageService.cacheAllFocusedPages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.fromSize(
                        size: PageModel.a4,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SizedBox.fromSize(
                        size: PageModel.a4,
                        child: Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      );
                    }
                    final editor = createEditorController(
                      focusedNote: noteStack.focusedNote!,
                      pageModel: noteStackPageService.currentPage,
                    );
                    debugPrint('editor: $editor');

                    return ChangeNotifierProvider.value(
                      value: noteStackPageService.currentPage,
                      child: Consumer<PageModel?>(
                        builder: (context, pageModel, child) {
                          debugPrint('current page rebuild');
                          if (pageModel == null) {
                            debugPrint('current page is null');
                            return const SizedBox();
                          }
                          return MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(
                                value: editor,
                              ),
                              ChangeNotifierProvider.value(
                                value: editor?.driver,
                              ),
                            ],
                            builder: (context, child) {
                              return BoardRendererLayout(
                                key: ValueKey(noteStackPageService.hashCode),
                              );
                            },
                          );
                        },
                      ),
                      builder: (context, child) {
                        return child ?? const SizedBox();
                      },
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}

class BoardRendererLayout extends HookWidget {
  const BoardRendererLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Toolbar(),
        Expanded(
          child: Stack(
            children: [
              RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                // multiple drag
                gestures: <Type, GestureRecognizerFactory>{
                  TwoFingerZoomGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          TwoFingerZoomGestureRecognizer>(
                    () => TwoFingerZoomGestureRecognizer(),
                    (TwoFingerZoomGestureRecognizer instance) {
                      instance.onStart = (details) {
                        if (details.pointerCount != 2) {
                          return;
                        }
                        var controller = Provider.of<DrawingBoardController>(
                            context,
                            listen: false);
                        controller.zoomStart(
                          details.localFocalPoint,
                        );
                      };
                      instance.onUpdate = (details) {
                        if (details.pointerCount != 2) {
                          return;
                        }
                        var controller = Provider.of<DrawingBoardController>(
                            context,
                            listen: false);
                        controller.zoomUpdate(
                            details.scale, details.localFocalPoint);
                      };
                      instance.onEnd = (details) {
                        var controller = Provider.of<DrawingBoardController>(
                            context,
                            listen: false);
                        controller.zoomEnd();
                      };
                    },
                  ),
                },
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      var controller = Provider.of<DrawingBoardController>(
                          context,
                          listen: false);
                      if (event.scrollDelta.dy > 0) {
                        controller.zoomOut();
                      } else {
                        controller.zoomIn();
                      }
                    }
                  },
                  child: CustomInteractiveViewer(
                    panAxis: PanAxis.free,
                    scaleEnabled: false,
                    constrained: false,
                    transformationController:
                        Provider.of<DrawingBoardController>(context,
                                listen: false)
                            .transformationController,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.1,
                    maxScale: 3,
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: Colors.white,
                      child: Consumer<NoteStackPageService>(
                        builder: (context, noteStackPageService, child) {
                          return Selector<NoteModelStack,
                              (List<NoteModel> notes, bool hasFocus)>(
                            selector: (context, noteStack) {
                              return (
                                noteStack.unfocusedNotes.toList(),
                                noteStack.hasFocus
                              );
                            },
                            shouldRebuild: (previous, next) {
                              return previous.$1.length != next.$1.length ||
                                  previous.$2 != next.$2 ||
                                  // check if any note id is different
                                  previous.$1.any((note) => !next.$1.any(
                                      (nextNote) => nextNote.id == note.id));
                            },
                            builder: (context, selectedData, child) {
                              return Stack(
                                children: [
                                  ...selectedData.$1.map(
                                    (noteModel) => PageStreamView(
                                      noteId: noteModel.id!,
                                      hasFocus: selectedData.$2,
                                      focusedNoteId: noteStackPageService
                                          .noteStack.focusedNote?.id,
                                    ),
                                  ),

                                  // focused note for editing
                                  if (selectedData.$2)
                                    PageRenderer(
                                      key: ValueKey(selectedData.$2),
                                      isEditable: true,
                                    ),

                                  // video elements from un-focused notes
                                  ...selectedData.$1
                                      .where((note) =>
                                          note.id !=
                                          noteStackPageService
                                              .noteStack.focusedNote?.id)
                                      .map(
                                        (noteModel) => VideoStreamView(
                                          noteId: noteModel.id!,
                                          hasFocus: selectedData.$2,
                                          focusedNoteId: noteStackPageService
                                              .noteStack.focusedNote?.id,
                                        ),
                                      ),

                                  // explanation elements from un-focused notes
                                  ...selectedData.$1
                                      .where((note) =>
                                          note.id !=
                                          noteStackPageService
                                              .noteStack.focusedNote?.id)
                                      .map(
                                        (noteModel) => ExplanationStreamView(
                                          noteId: noteModel.id!,
                                          hasFocus: selectedData.$2,
                                          focusedNoteId: noteStackPageService
                                              .noteStack.focusedNote?.id,
                                        ),
                                      ),

                                  // marking container at the left side
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: noteStackPageService
                                                .noteStack.focusedNote?.id ==
                                            null
                                        ? const SizedBox()
                                        : FutureBuilder(
                                            future: noteStackPageService
                                                .getCurrentMarkings(
                                              getMarking:
                                                  Provider.of<NoteScreenStateWrapper>(
                                                              context,
                                                              listen: false)
                                                          .state ==
                                                      NoteScreenState
                                                          .viewingExercise,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              if (snapshot.hasError) {
                                                debugPrint(
                                                    'getCurrentMarkings Error: ${snapshot.error}');
                                                return Center(
                                                  child: Text(
                                                    'getCurrentMarkings Error: ${snapshot.error}',
                                                  ),
                                                );
                                              }
                                              if (!snapshot.hasData) {
                                                return const Center(
                                                  child: Text(
                                                    'No data',
                                                  ),
                                                );
                                              }
                                              if (noteStackPageService
                                                      .currentPage?.id ==
                                                  null) {
                                                return const SizedBox();
                                              }
                                              final noteState = Provider.of<
                                                          NoteScreenStateWrapper>(
                                                      context,
                                                      listen: false)
                                                  .state;
                                              DraggableContainerState?
                                                  draggableState;
                                              switch (noteState) {
                                                case NoteScreenState
                                                      .editingTemplate:
                                                  draggableState =
                                                      DraggableContainerState
                                                          .creating;
                                                  break;
                                                case NoteScreenState
                                                      .startedMarking:
                                                  draggableState =
                                                      DraggableContainerState
                                                          .editing;
                                                  break;
                                                case NoteScreenState
                                                      .finishedMarking:
                                                case NoteScreenState
                                                      .viewingExercise:
                                                  draggableState =
                                                      DraggableContainerState
                                                          .readOnly;
                                                  break;
                                                default:
                                                  draggableState = null;
                                              }
                                              if (draggableState == null) {
                                                return const SizedBox();
                                              }
                                              debugPrint(
                                                  "Showing marking container");
                                              final exerciseNote =
                                                  noteStackPageService.noteStack
                                                      .getNoteByNoteType(
                                                          NoteType.exercise);
                                              return SizedBox();
                                              // return DraggableContainer(
                                              //   key: ValueKey(
                                              //       noteStackPageService
                                              //           .currentPage?.id),
                                              //   state: draggableState,
                                              //   pageId: noteStackPageService
                                              //           .currentPage?.id ??
                                              //       '',
                                              //   defaultMarkings:
                                              //       snapshot.data ?? [],
                                              //   onMarkingsChange: (markings) {
                                              //     noteStackPageService
                                              //         .updateCurrentPageMarkings(
                                              //       markings: markings,
                                              //     );
                                              //   },
                                              //   overallScoreWidget:
                                              //       exerciseNote == null
                                              //           ? null
                                              //           : OverallScoreWidget(
                                              //               templateReference:
                                              //                   noteStackPageService
                                              //                       .noteStack
                                              //                       .template,
                                              //               exerciseReference:
                                              //                   exerciseNote,
                                              //             ),
                                              // );
                                            },
                                          ),
                                  ),

                                  // loading indicator
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: noteStackPageService
                                          .isLoadingNotifier,
                                      builder: (context, isLoading, child) {
                                        if (isLoading) {
                                          return Container(
                                            color:
                                                Colors.black.withOpacity(0.7),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 100.0, // Desired width
                                                height: 100.0, // Desired height
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      8.0, // Adjust thickness if desired
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Colors
                                                              .white), // Change color if needed
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  // if (noteStackPageService
                                  //     .isLoadingNotifier.value)
                                  //   const Center(
                                  //     child: CircularProgressIndicator(),
                                  //   ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // saving indicator
              const Positioned(
                top: 10,
                left: 10,
                child: SavingIndicator(),
              ),

              const Positioned(
                top: 10,
                right: 10,
                child: ZoomControls(),
              ),

              const Positioned.fill(
                bottom: 40,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: EditorControls(),
                ),
              ),

              const Positioned.fill(
                bottom: 40,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: DrawingControls(),
                ),
              ),

              const Positioned.fill(
                bottom: 40,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: EditorHint(),
                  ),
                ),
              ),

              // inspecting user
              Selector<NoteModelStack, String?>(
                  selector: (context, noteStack) => noteStack.template.id,
                  builder: (context, templateId, child) {
                    if (templateId == null) {
                      return const SizedBox();
                    }
                    return Consumer<InspectingUserWrapper>(
                        builder: (context, inspectingUserWrapper, child) {
                      if (inspectingUserWrapper.user == null) {
                        return const SizedBox();
                      }
                      return InspectingUserToolbar(
                        userId: inspectingUserWrapper.user!.uid,
                        selectedNoteId: inspectingUserWrapper.noteId!,
                        templateId: templateId,
                      );
                    });
                  }),
            ],
          ),
        ),
      ],
    );
  }
}

class InspectingUserToolbar extends HookWidget {
  const InspectingUserToolbar({
    super.key,
    required this.userId,
    required this.templateId,
    required this.selectedNoteId,
  });

  final String userId;
  final String templateId;
  final String selectedNoteId;

  @override
  Widget build(BuildContext context) {
    // final noteService = Provider.of<NoteService>(context);

    // Define the debounce duration (e.g., 300 milliseconds)
    const debounceDuration = Duration(milliseconds: 300);

    // Use a ref to hold the Timer
    final debounceTimer = useRef<Timer?>(null);

    final changeUser = useCallback((
      List<NoteModel> overlayNotes,
      int noteIndex,
      bool prev,
    ) async {
      var noteStack = Provider.of<NoteModelStack>(context, listen: false);

      var drawingBoardController =
          Provider.of<DrawingBoardController>(context, listen: false);

      var inspectingUserWrapper =
          Provider.of<InspectingUserWrapper>(context, listen: false);

      NoteModel note;
      if (prev) {
        if (noteIndex <= 0) {
          return;
        }

        note = overlayNotes[noteIndex - 1];
      } else {
        if (noteIndex == -1) {
          return;
        }

        if (noteIndex >= overlayNotes.length - 1) {
          return;
        }

        note = overlayNotes[noteIndex + 1];
      }

      // Cancel any existing timer
      debounceTimer.value?.cancel();

      // Start a new timer
      debounceTimer.value = Timer(debounceDuration, () async {
        var nextUser = await Provider.of<UserService>(context, listen: false)
            .getUser(note.createdBy);

        drawingBoardController.isHighlighting = true;
        inspectingUserWrapper.set(
          nextUser,
          note.id,
        );

        if (!context.mounted) {
          return;
        }

        final noteService = Provider.of<NoteService>(context, listen: false);

        var userNoteStack = await noteService.getNestedNotes(noteId: note.id!);

        // create a new overlay note if the last overlay is not a marking note
        if (!userNoteStack.hasNoteType(NoteType.marking)) {
          debugPrint('creating new marking note');
          await noteService.createOverlayNote(
              userNoteStack.overlays.last, NoteType.marking);
        }

        noteStack.clearOverlays();
        noteStack.mergeStack(userNoteStack);
        noteStack.focusOverlayByCreator(noteService.getUserId()!);
      });
    }, [debounceDuration, context]);

    // Ensure the timer is canceled when the widget is disposed
    useEffect(() {
      return () {
        debounceTimer.value?.cancel();
      };
    }, []);

    final clearUser = useCallback(() {
      var noteStack = Provider.of<NoteModelStack>(context, listen: false);

      var drawingBoardController =
          Provider.of<DrawingBoardController>(context, listen: false);

      var inspectingUserWrapper =
          Provider.of<InspectingUserWrapper>(context, listen: false);

      drawingBoardController.isHighlighting = false;
      inspectingUserWrapper.clear();
      noteStack.clearOverlays();
      noteStack.focusTemplate();
    }, []);

    return Positioned(
      bottom: 25,
      left: 0,
      right: 0,
      child: MultiProvider(
        providers: [
          FutureProvider.value(
            value: Provider.of<UserService>(context, listen: false)
                .getUser(userId),
            initialData: null,
          ),
          FutureProvider.value(
            value: Provider.of<NoteService>(context, listen: false)
                .getOverlayNotes(noteId: templateId, type: NoteType.exercise),
            initialData: const <NoteModel>[],
          ),
        ],
        builder: (context, child) {
          final user = Provider.of<UserModel?>(context);
          final overlayNotes = Provider.of<List<NoteModel>>(context);

          final noteIndex =
              overlayNotes.indexWhere((note) => note.id == selectedNoteId);

          if (user == null) {
            return const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  )),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  // previous response button
                  if (overlayNotes.isNotEmpty && noteIndex > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () async {
                        await changeUser(overlayNotes, noteIndex, true);
                      },
                    ),

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      user.photoUrl == null
                          ? const CircleAvatar(
                              child: Icon(Icons.person),
                            )
                          : CircleAvatar(
                              radius: 15,
                              backgroundImage: NetworkImage(user.photoUrl!),
                            ),
                      Text(
                        user.name ?? user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          clearUser();
                        },
                      )
                    ],
                  ),

                  // next response button
                  if (overlayNotes.isNotEmpty &&
                      noteIndex < overlayNotes.length - 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () async {
                        await changeUser(overlayNotes, noteIndex, false);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PageStreamView extends HookWidget {
  const PageStreamView({
    super.key,
    required this.noteId,
    required this.hasFocus,
    this.focusedNoteId,
  });

  final String noteId;
  final bool hasFocus;
  final String? focusedNoteId;

  @override
  Widget build(BuildContext context) {
    final noteStackPageService = Provider.of<NoteStackPageService>(context);

    final pageModel = useState<PageModel?>(null);

    useEffect(() {
      final currentPageStream =
          noteStackPageService.getCurrentPageStream(noteId).listen((event) {
        debugPrint('page stream view: ${event.id}');
        pageModel.value = event;
      });

      return () {
        debugPrint('page stream view: dispose');
        currentPageStream.cancel();
      };
    }, [noteId]);

    if (pageModel.value == null || noteId == focusedNoteId) {
      return SizedBox.fromSize(
        size: PageModel.a4,
      );
    }

    return ChangeNotifierProvider.value(
      value: pageModel.value!,
      builder: (context, child) {
        return child ?? const SizedBox();
      },
      child: PageRenderer(
        key: ValueKey(pageModel.value!.id),
      ),
    );
  }
}

class ExplanationStreamView extends HookWidget {
  const ExplanationStreamView({
    super.key,
    required this.noteId,
    required this.hasFocus,
    this.focusedNoteId,
  });

  final String noteId;
  final bool hasFocus;
  final String? focusedNoteId;

  @override
  Widget build(BuildContext context) {
    final noteStackPageService = Provider.of<NoteStackPageService>(context);

    final pageModel = useState<PageModel?>(null);

    useEffect(() {
      final currentPageStream =
          noteStackPageService.getCurrentPageStream(noteId).listen((event) {
        debugPrint('ExplanationStreamView: ${event.id}');
        pageModel.value = event;
      });

      return () {
        debugPrint('ExplanationStreamView: dispose');
        currentPageStream.cancel();
      };
    }, const []);

    if (pageModel.value == null || noteId == focusedNoteId) {
      return IgnorePointer(
        ignoring: true,
        child: SizedBox.fromSize(
          size: PageModel.a4,
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: pageModel.value!,
      builder: (context, child) {
        return Selector<PageModel, Size>(
          selector: (context, page) => page.size,
          builder: (context, size, child) {
            return Container(
              clipBehavior: Clip.none,
              width: size.width,
              height: size.height,
              child: Selector<PageModel, List<GraphicElementModel>>(
                selector: (context, pageModel) => pageModel.graphicElements,
                shouldRebuild: (previous, next) => true,
                builder: (context, graphicElements, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < graphicElements.length; i++)
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                              value: graphicElements[i],
                            ),
                            ChangeNotifierProvider<EditorController?>.value(
                              value: null,
                            ),
                          ],
                          builder: (context, child) {
                            final noteStack =
                                Provider.of<NoteModelStack>(context);
                            final stateWrapper =
                                Provider.of<NoteScreenStateWrapper?>(context);

                            // hide explanation element if it is not published
                            if (graphicElements[i].type !=
                                    GraphicElementType.explanation ||
                                (noteStack.template.hideExplanation == true &&
                                    stateWrapper?.state !=
                                        NoteScreenState.editingTemplate)) {
                              return const SizedBox();
                            }
                            return Consumer<GraphicElementModel>(
                              builder: (context, element, child) {
                                return Positioned.fromRect(
                                  rect: element.bounds,
                                  child: IgnorePointer(
                                    ignoring: element.type ==
                                        GraphicElementType.drawing,
                                    child: BaseGraphicElement(
                                      graphicElement: element,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: null,
                                        child: GraphicElementModel
                                            .getElementWidget(
                                          element: element,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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

class VideoStreamView extends HookWidget {
  const VideoStreamView({
    super.key,
    required this.noteId,
    required this.hasFocus,
    this.focusedNoteId,
  });

  final String noteId;
  final bool hasFocus;
  final String? focusedNoteId;

  @override
  Widget build(BuildContext context) {
    final noteStackPageService = Provider.of<NoteStackPageService>(context);

    final pageModel = useState<PageModel?>(null);

    useEffect(() {
      final currentPageStream =
          noteStackPageService.getCurrentPageStream(noteId).listen((event) {
        debugPrint('VideoStreamView: ${event.id}');
        pageModel.value = event;
      });

      return () {
        debugPrint('VideoStreamView: dispose');
        currentPageStream.cancel();
      };
    }, const []);

    if (pageModel.value == null || noteId == focusedNoteId) {
      return IgnorePointer(
        ignoring: true,
        child: SizedBox.fromSize(
          size: PageModel.a4,
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: pageModel.value!,
      builder: (context, child) {
        return Selector<PageModel, Size>(
          selector: (context, page) => page.size,
          builder: (context, size, child) {
            return Container(
              clipBehavior: Clip.none,
              width: size.width,
              height: size.height,
              child: Selector<PageModel, List<GraphicElementModel>>(
                selector: (context, pageModel) => pageModel.graphicElements,
                shouldRebuild: (previous, next) => true,
                builder: (context, graphicElements, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < graphicElements.length; i++)
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                              value: graphicElements[i],
                            ),
                            ChangeNotifierProvider<EditorController?>.value(
                              value: null,
                            ),
                          ],
                          builder: (context, child) {
                            return Consumer<GraphicElementModel>(
                              builder: (context, element, child) {
                                return Positioned.fromRect(
                                  rect: element.bounds,
                                  child: IgnorePointer(
                                    ignoring: element.type ==
                                        GraphicElementType.drawing,
                                    child: BaseGraphicElement(
                                      graphicElement: element,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: null,
                                        child: GraphicElementModel
                                            .getElementWidget(
                                          element: element,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
