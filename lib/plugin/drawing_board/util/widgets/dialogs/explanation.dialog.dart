import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/widgets/video_player_with_control.dart';

import '../../../controllers/editor.controller.dart';
import '../../../graphic_elements/explanation_element.dart';
import '../../../models/explanation_element_model.dart';

class ExplanationDialog extends HookWidget {
  const ExplanationDialog({
    super.key,
    required this.noteId,
    required this.explanationElement,
    required this.controller,
    required this.noteStack,
  });

  final String noteId;
  final ExplanationElementModel explanationElement;
  final EditorController? controller;
  final NoteModelStack noteStack;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: ExplanationTitle(
        explanationElement: explanationElement,
        controller: controller,
      ),
      actions: [
        ListenableBuilder(
          listenable: explanationElement,
          builder: (context, child) {
            // delete button
            if (controller != null &&
                !explanationElement.content.hasEmptyPath) {
              return TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).extension<CustomColors>()?.danger,
                ),
                onPressed: () {
                  explanationElement.updateWith(
                    content: Uri.parse(''),
                  );
                  controller!.updateStateToRef();
                },
                label: const Text('Remove'),
                icon: const Icon(Icons.delete),
              );
            } else {
              return const SizedBox();
            }
          },
        ),

        // save/close button
        if (controller != null)
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor:
                  Theme.of(context).extension<CustomColors>()?.success,
              foregroundColor:
                  Theme.of(context).extension<CustomColors>()?.onSuccess,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            label: const Text('Save'),
            icon: const Icon(Icons.save),
          )
        else
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            label: const Text('Close'),
            icon: const Icon(Icons.close),
          ),
      ],
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ListenableBuilder(
          listenable: explanationElement,
          builder: (context, child) {
            return Stack(
              children: [
                if (controller != null &&
                    explanationElement.content.hasEmptyPath) ...[
                  // video upload zone
                  VideoUploadZone(
                    noteId: noteId,
                    explanationElement: explanationElement,
                    controller: controller!,
                    noteStack: noteStack,
                  ),
                ] else ...[
                  // video player
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withAlpha(85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: explanationElement.content.hasEmptyPath
                          ? Center(
                              child: Text(
                              'Nothing here yet',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ))
                          : Center(
                              child: VideoPlayerWithControl(
                                url: explanationElement.content,
                              ),
                            ),
                    ),
                  ),
                ],

                // remove video button
                if (controller != null &&
                    !explanationElement.content.hasEmptyPath) ...[
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        explanationElement.updateWith(
                          content: Uri.parse(''),
                        );
                        controller!.updateStateToRef();
                      },
                      icon: const Icon(
                        FontAwesomeIcons.x,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
