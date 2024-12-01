import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/helpers/upload.helper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../controllers/editor.controller.dart';
import '../models/video_element_model.dart';
import '../util/show_dialogs.dart';

class VideoElement extends HookWidget {
  const VideoElement({
    super.key,
    required this.videoElement,
  });

  final VideoElementModel videoElement;

  @override
  Widget build(BuildContext context) {
    var enabled = useState(false);
    final controller = Provider.of<EditorController?>(context);
    final noteStack = Provider.of<NoteModelStack>(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Visibility(
        visible: videoElement.visibility,
        child: IgnorePointer(
          ignoring: controller != null &&
              controller.elementState.hashCode != videoElement.hashCode,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              debugPrint('Video element tapped');
              enabled.value = true;

              if (noteStack.focusedNote == null) {
                debugPrint('No focused note');
                return;
              }

              // open video dialog
              await showVideoDialog(
                context: context,
                videoElement: videoElement,
                controller: controller,
                noteId: noteStack.focusedNote!.id!,
              );
            },
            child: Card(
              // add border size
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              color: Theme.of(context).colorScheme.background,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.video_library,
                    color: Colors.red,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoTitle extends HookWidget {
  const VideoTitle({
    super.key,
    required this.videoElement,
    required this.controller,
  });

  final VideoElementModel videoElement;
  final EditorController? controller;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(
      text: videoElement.title,
    );
    final debouncer = useRef<Debouncer>(Debouncer(milliseconds: 300));

    useEffect(() {
      return () {
        debouncer.value.dispose();
      };
    }, [debouncer]);

    if (controller == null) {
      return Text(
        videoElement.title,
        style: Theme.of(context).textTheme.headlineMedium,
      );
    }
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      controller: textController,
      onChanged: (value) {
        videoElement.updateWith(
          title: value,
        );

        // update element
        debouncer.value.run(() {
          controller!.updateStateToRef();
        });
      },
    );
  }
}

class VideoUploadZone extends HookWidget {
  const VideoUploadZone({
    super.key,
    required this.noteId,
    required this.videoElement,
    required this.controller,
    required this.noteStack,
  });

  final String noteId;
  final VideoElementModel videoElement;
  final EditorController controller;
  final NoteModelStack noteStack;

  @override
  Widget build(BuildContext context) {
    final uploading = useState(false);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(85),
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          uploading.value = true;
          final url = await showPickFileDialog(
              context: context,
              fileType: FileType.video,
              prefix: noteStack.focusedNote?.id);

          if (url == null) {
            uploading.value = false;
            return;
          }

          videoElement.updateWith(
            content: Uri.parse(url),
          );
          // update element
          controller.updateStateToRef();
          uploading.value = false;
        },
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (uploading.value) ...[
                  // upload progress
                  const CircularProgressIndicator()
                ] else ...[
                  Icon(
                    FontAwesomeIcons.video,
                    color: Theme.of(context).extension<CustomColors>()?.warning,
                  ),
                  const Text('Click to upload video'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
