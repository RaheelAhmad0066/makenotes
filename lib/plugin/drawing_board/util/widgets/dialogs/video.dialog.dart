import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/widgets/video_player_with_control.dart';

import '../../../controllers/editor.controller.dart';
import '../../../graphic_elements/video_element.dart';
import '../../../models/video_element_model.dart';

class VideoDialog extends HookWidget {
  const VideoDialog({
    super.key,
    required this.noteId,
    required this.videoElement,
    required this.controller,
    required this.noteStack,
  });

  final String noteId;
  final VideoElementModel videoElement;
  final EditorController? controller;
  final NoteModelStack noteStack;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: VideoTitle(
        videoElement: videoElement,
        controller: controller,
      ),
      actions: [
        ListenableBuilder(
          listenable: videoElement,
          builder: (context, child) {
            // delete button
            if (controller != null && !videoElement.content.hasEmptyPath) {
              return TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).extension<CustomColors>()?.danger,
                ),
                onPressed: () {
                  videoElement.updateWith(
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
          listenable: videoElement,
          builder: (context, child) {
            return Stack(
              children: [
                if (controller != null &&
                    videoElement.content.hasEmptyPath) ...[
                  // video upload zone
                  VideoUploadZone(
                    noteId: noteId,
                    videoElement: videoElement,
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
                      child: videoElement.content.hasEmptyPath
                          ? Center(
                              child: Text(
                              'Nothing here yet',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ))
                          : Center(
                              child: VideoPlayerWithControl(
                                url: videoElement.content,
                              ),
                            ),
                    ),
                  ),
                ],

                // remove video button
                if (controller != null &&
                    !videoElement.content.hasEmptyPath) ...[
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        videoElement.updateWith(
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
