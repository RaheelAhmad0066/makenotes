import 'package:flutter/material.dart' hide TransformationController;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/models/inspecting_user.wrapper.dart';
import 'package:makernote/plugin/drawing_board/board.renderer.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/graphic_elements/flutter_drawing_board_element.dart';
import 'package:makernote/plugin/drawing_board/services/editor_mc_service.dart';
import 'package:makernote/plugin/drawing_board/services/note_stack_page.service.dart';
import 'package:makernote/plugin/drawing_board/services/timer_service.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/custom_interactive_viewer.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/mc_list.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/mc_result.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/services/item/page.service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/utils/note_state.dart';
import 'package:makernote/widgets/explanation_list.panel.dart';
import 'package:makernote/widgets/note_screen_app_bar.dart';
import 'package:makernote/widgets/response_list.dart';
import 'package:provider/provider.dart';

class NoteScreen extends HookWidget {
  const NoteScreen({
    super.key,
    this.noteId,
    this.ownerId,
  });
  final String? noteId;
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    if (noteId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No note id provided'),
        ),
      );
    }

    return NestedNoteStreamView(
      key: ValueKey(noteId),
      noteId: noteId!,
      ownerId: ownerId,
    );
  }
}

class NestedNoteStreamView extends HookWidget {
  const NestedNoteStreamView({
    super.key,
    required this.noteId,
    this.ownerId,
  });

  final String noteId;
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);

    final noteStack = useState<NoteModelStack?>(null);

    final drawingBoardController = useMemoized(
      () => DrawingBoardController(
        transformationController: TransformationController(),
      ),
    );

    final noteSaverTimer = useMemoized(() => TimerService(interval: 5), []);

    useEffect(() {
      final noteStackStreamController =
          noteService.getNestedNotesStream(noteId: noteId, ownerId: ownerId);

      final noteStackStream = noteStackStreamController.stream.listen((event) {
        debugPrint('NestedNoteStreamView: ${event.allNotes.length}');
        noteStack.value = event;
      });

      noteSaverTimer.startTimer();

      return () {
        debugPrint('NestedNoteStreamView: dispose');
        noteStackStream.cancel();
        noteSaverTimer.stopTimer();
        noteSaverTimer.dispose();
        noteStackStreamController.close();
        drawingBoardController.dispose();
      };
    }, const []);

    if (noteStack.value == null) {
      return Scaffold(
        body: Center(
          child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            children: [
              const CircularProgressIndicator(),

              // back button
              TextButton(
                onPressed: () {
                  noteSaverTimer.forceTrigger();

                  beamerKey.currentState?.routerDelegate.beamBack();
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }
    return MultiProvider(
      key: ValueKey(noteStack.value.hashCode),
      providers: [
        ChangeNotifierProvider.value(value: noteSaverTimer),
        ChangeNotifierProvider.value(value: drawingBoardController),
        ChangeNotifierProvider<DrawingControllersProvider>(
          create: (_) => DrawingControllersProvider(),
        ),
        ChangeNotifierProvider.value(value: noteStack.value),
        ChangeNotifierProxyProvider<NoteModelStack, NoteScreenStateWrapper>(
          create: (_) =>
              NoteScreenStateWrapper(getNoteStackState(noteStack.value!)),
          update: (_, noteModelStack, noteScreenStateWrapper) {
            // Compute the new state
            final newState = getNoteStackState(noteModelStack);

            // Instead of calling setState directly, update the wrapper state safely
            if (noteScreenStateWrapper == null ||
                noteScreenStateWrapper.state != newState) {
              // Create a new wrapper with the updated state
              return NoteScreenStateWrapper(newState);
            }

            // Return the current wrapper if no state change is required
            return noteScreenStateWrapper;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => MultiPanelController.fromNames([
            'mcList',
            'mcResult',
            'responseList',
            'explanationList',
          ]),
        ),
        ChangeNotifierProvider(create: (_) => InspectingUserWrapper()),
        ChangeNotifierProxyProvider<NoteModelStack, NoteStackPageService>(
          create: (_) => NoteStackPageService(
            pageService: Provider.of<PageService>(context),
            noteService: noteService,
            noteStack: noteStack.value!,
            disableCache: false,
          ),
          update: (_, noteStack, noteStackPageService) {
            return NoteStackPageService(
              pageService: noteStackPageService?.pageService ??
                  Provider.of<PageService>(context),
              noteService: noteStackPageService?.noteService ?? noteService,
              noteStack: noteStack,
              initialCurrentPageIndex:
                  noteStackPageService?.currentPageIndex ?? 0,
              disableCache: false,
            );
          },
        ),
      ],
      builder: (context, child) {
        debugPrint('building note screen from provider: \n'
            '\t note: ${noteStack.value.hashCode} (count: ${noteStack.value?.allNotes.length}) \n'
            '\t notes: ${noteStack.value?.allNotes.map((e) => e.id).join(', ')} \n'
            '\t controller: ${drawingBoardController.hashCode} \n'
            '\t multiPanelController: ${Provider.of<MultiPanelController>(context).hashCode} \n'
            '\t inspectingUserWrapper: ${Provider.of<InspectingUserWrapper>(context).hashCode} \n');
        return NoteModelStackView(
          key: ValueKey(noteStack.value.hashCode),
        );
      },
    );
  }
}

class NoteModelStackView extends HookWidget {
  const NoteModelStackView({super.key});

  @override
  Widget build(BuildContext context) {
    final mcService = Provider.of<MCService>(context);
    return SafeArea(
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: NoteScreenAppBar(),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: BoardRenderer(
                key: ValueKey('boardRenderer'),
              ),
            ),

            Expanded(
              flex: 0,
              child: Consumer<MultiPanelController>(
                builder: (context, multiPanelController, child) {
                  return Selector<NoteModelStack, NoteModel>(
                    selector: (context, noteStack) =>
                        noteStack.focusedNote ?? noteStack.template,
                    builder: (context, noteModel, child) {
                      return ChangeNotifierProvider(
                        key: ValueKey(noteModel.id),
                        create: (_) => EditorMCService(
                          noteMCService: mcService,
                          note: noteModel,
                          ownerId: noteModel.ownerId,
                        ),
                        builder: (context, child) {
                          return MCList(
                            controllerKey: 'mcList',
                            controller: multiPanelController,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // mc result
            Expanded(
              flex: 0,
              child: Consumer<MultiPanelController>(
                builder: (context, multiPanelController, child) {
                  return Consumer<NoteModelStack>(
                    builder: (context, noteStack, child) {
                      final exerciseNote = noteStack.overlays
                          .where((element) =>
                              element.noteType == NoteType.exercise)
                          .firstOrNull;
                      if (exerciseNote == null) return const SizedBox();
                      return MCResult(
                        controllerKey: 'mcResult',
                        controller: multiPanelController,
                        templateReference: noteStack.template.toReference(),
                        targetReference: exerciseNote.toReference(),
                        onPanelClose: () {
                          multiPanelController.closePanel('mcResult');
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // response list
            Expanded(
              flex: 0,
              child: Consumer<MultiPanelController>(
                builder: (context, multiPanelController, child) {
                  return Selector<NoteModelStack, NoteModel>(
                    selector: (context, noteStack) => noteStack.template,
                    shouldRebuild: (previous, next) {
                      return previous.id != next.id;
                    },
                    builder: (context, noteModel, child) {
                      return ResponseList(
                        key: ValueKey(noteModel.id),
                        controllerKey: 'responseList',
                        controller: multiPanelController,
                        noteId: noteModel.id!,
                      );
                    },
                  );
                },
              ),
            ),

            // explanation list
            Expanded(
              flex: 0,
              child: Consumer<MultiPanelController>(
                builder: (context, multiPanelController, child) {
                  return Selector<NoteModelStack, NoteModel>(
                    selector: (context, noteStack) => noteStack.template,
                    shouldRebuild: (previous, next) {
                      return previous.id != next.id;
                    },
                    builder: (context, noteModel, child) {
                      if (!multiPanelController
                          .isPanelOpen('explanationList')) {
                        return const SizedBox();
                      }
                      return ExplanationListPanel(
                        controllerKey: 'explanationList',
                        controller: multiPanelController,
                        noteId: noteModel.id!,
                        noteModel: noteModel,
                        ownerId: noteModel.ownerId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteScreenStateWrapper extends ChangeNotifier {
  NoteScreenStateWrapper(this.state);
  NoteScreenState state;

  void setState(NoteScreenState newState) {
    state = newState;
    notifyListeners();
  }
}
