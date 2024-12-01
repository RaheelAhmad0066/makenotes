import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/show_dialogs.dart';
import 'package:makernote/screens/notes/note_screen.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/utils/note_state.dart';
import 'package:provider/provider.dart';

class ExplanationListPanel extends HookWidget {
  const ExplanationListPanel({
    super.key,
    required this.controllerKey,
    required this.controller,
    required this.noteId,
    required this.noteModel,
    this.ownerId,
  });
  final String controllerKey;
  final MultiPanelController controller;
  final String noteId;
  final NoteModel noteModel;
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);

    final explanations = useState<List<ExplanationElementModel>?>(null);

    final stateWrapper =
        Provider.of<NoteScreenStateWrapper>(context, listen: false);
    final state = stateWrapper.state;

    useEffect(() {
      final stream = noteService
          .getExplanationsStream(noteId: noteId, ownerId: ownerId)
          .listen((list) {
        debugPrint('explanations stream view: ${list.length}');
        explanations.value = list;
      });

      return () {
        debugPrint('explanations stream view: cancel');
        stream.cancel();
      };
    }, const []);
    return GestureDetector(
      behavior:
          HitTestBehavior.opaque, // Ensures entire area is swipe-sensitive
      onHorizontalDragUpdate: (details) {
        // Detect swipe to the left (swipe distance threshold to prevent accidental swipes)
        if (details.delta.dx > 15) {
          // Adjust threshold as needed
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
                    child: Column(
                      children: [
                        // header
                        Row(
                          children: [
                            // title
                            Expanded(
                              child: Text(
                                'Explanations',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
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

                        if (explanations.value == null) ...[
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ] else ...[
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // states
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // total
                                      Text(
                                        '${explanations.value?.where((explanation) {
                                              final isAllowEditing =
                                                  <NoteScreenState>[
                                                NoteScreenState.editingTemplate,
                                              ].contains(stateWrapper.state);
                                              final visible = isAllowEditing ||
                                                  (explanation.published &&
                                                      !noteModel
                                                          .hideExplanation);
                                              return visible;
                                            }).length ?? 0} total',
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

                                  ExplanationList(
                                    noteModel: noteModel,
                                    explanations: explanations.value ?? [],
                                    onExplanationTap: (explanation) async {
                                      await showExplanationDialog(
                                        context: context,
                                        explanationElement: explanation,
                                        noteId: noteId,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],

                        const Divider(),

                        // state: editing template
                        if (state == NoteScreenState.editingTemplate) ...[
                          // hide explanation switch
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Hide All Explanation'),
                              ChangeNotifierProvider.value(
                                value: noteModel,
                                builder: (context, child) {
                                  return Consumer<NoteModel>(
                                    builder: (context, note, child) {
                                      return Switch(
                                        value: note.hideExplanation,
                                        onChanged: (value) async {
                                          await noteService.setHideExplanation(
                                            note: note,
                                            hideExplanation: value,
                                          );
                                          note.setHideExplanation(value);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
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

class ExplanationList extends HookWidget {
  const ExplanationList({
    super.key,
    required this.noteModel,
    required this.explanations,
    this.onExplanationTap,
  });
  final NoteModel noteModel;
  final List<ExplanationElementModel> explanations;

  final void Function(ExplanationElementModel)? onExplanationTap;

  @override
  Widget build(BuildContext context) {
    final stateWrapper = Provider.of<NoteScreenStateWrapper>(context);
    debugPrint('state: ${stateWrapper.state}');
    return ListView.builder(
      cacheExtent: 0.0,
      shrinkWrap: true,
      itemCount: explanations.length,
      itemBuilder: (context, index) {
        final explanation = explanations[index];
        final isAllowEditing = <NoteScreenState>[
          NoteScreenState.editingTemplate,
        ].contains(stateWrapper.state);
        final visible = isAllowEditing ||
            (explanation.published && !noteModel.hideExplanation);
        if (!visible) {
          return const SizedBox();
        }
        return ListTile(
          leading: const Icon(Icons.video_library),
          onTap: () {
            if (onExplanationTap != null) {
              onExplanationTap!(explanation);
            }
          },
          title: Text(
            explanation.title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: isAllowEditing
              ? explanation.published
                  ? const Icon(Icons.visibility)
                  : const Icon(Icons.visibility_off)
              : null,
        );
      },
    );
  }
}
