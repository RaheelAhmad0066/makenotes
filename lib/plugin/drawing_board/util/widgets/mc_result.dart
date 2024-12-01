import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:provider/provider.dart';

class MCResult extends HookWidget {
  const MCResult({
    super.key,
    required this.controllerKey,
    required this.controller,
    required this.templateReference,
    required this.targetReference,
    this.onPanelClose,
  });

  final void Function()? onPanelClose;

  final String controllerKey;
  final MultiPanelController controller;
  final NoteReferenceModel templateReference;
  final NoteReferenceModel targetReference;

  @override
  Widget build(BuildContext context) {
    final mcService = Provider.of<MCService>(context);

    final showCorrectAnswers = useState(false);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return AnimatedSize(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 0,
              maxWidth: 400,
            ),
            child: SizedBox(
              width: controller.isPanelOpen(controllerKey) ? null : 0,
              child: Visibility(
                visible: controller.isPanelOpen(controllerKey),
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: controller.isPanelOpen(controllerKey) ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // header
                        Row(
                          children: [
                            // title
                            Expanded(
                              child: Text(
                                'MC Result',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),

                            // close button
                            IconButton(
                              onPressed: () {
                                onPanelClose?.call();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const Divider(),

                        Expanded(
                          child: FutureBuilder(
                            future: Future.wait(
                              [
                                mcService.getMC(templateReference.noteId,
                                    templateReference.ownerId),
                                mcService.getMC(targetReference.noteId,
                                    targetReference.ownerId),
                              ],
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
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
                              final mcTemplate = snapshot.data![0];
                              final mcExercise = snapshot.data![1];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        ...mcTemplate.asMap().entries.map(
                                              (e) => ListTile(
                                                leading: Text(
                                                  '${e.key + 1}',
                                                ),
                                                title: Text(
                                                    mcExercise[e.key]
                                                            .correctAnswer
                                                            ?.toString()
                                                            .split('.')
                                                            .last ??
                                                        '(no answer)',
                                                    style: TextStyle(
                                                      color: mcExercise[e.key]
                                                                  .correctAnswer ==
                                                              null
                                                          ? Colors.grey
                                                          : mcExercise[e.key]
                                                                      .correctAnswer ==
                                                                  e.value
                                                                      .correctAnswer
                                                              ? Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      CustomColors>()
                                                                  ?.success
                                                              : Theme.of(
                                                                      context)
                                                                  .extension<
                                                                      CustomColors>()
                                                                  ?.danger,
                                                    )),
                                                subtitle: showCorrectAnswers
                                                        .value
                                                    ? Text(
                                                        'Correct answer: ${e.value.correctAnswer?.toString().split('.').last ?? ''}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    : null,
                                                trailing: mcExercise[e.key]
                                                            .correctAnswer ==
                                                        null
                                                    ? const Icon(
                                                        Icons.question_mark,
                                                        color: Colors.grey,
                                                      )
                                                    : mcExercise[e.key]
                                                                .correctAnswer ==
                                                            e.value
                                                                .correctAnswer
                                                        ? Icon(
                                                            Icons.check,
                                                            color: Theme.of(
                                                                    context)
                                                                .extension<
                                                                    CustomColors>()
                                                                ?.success,
                                                          )
                                                        : Icon(
                                                            Icons.close,
                                                            color: Theme.of(
                                                                    context)
                                                                .extension<
                                                                    CustomColors>()
                                                                ?.danger,
                                                          ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),

                                  // overall result
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // show correct answers switch
                                        Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  showCorrectAnswers.value =
                                                      !showCorrectAnswers.value;
                                                },
                                                icon: Icon(showCorrectAnswers
                                                        .value
                                                    ? Icons.visibility
                                                    : Icons.visibility_off)),
                                          ],
                                        ),

                                        Text(
                                          'Overall result: ${mcExercise.where((element) => element.correctAnswer == mcTemplate[mcExercise.indexOf(element)].correctAnswer).length}/${mcExercise.length}',
                                        ),
                                      ],
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
    );
  }
}
