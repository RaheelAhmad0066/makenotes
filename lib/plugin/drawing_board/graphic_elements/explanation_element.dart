import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:makernote/plugin/drawing_board/util/show_dialogs.dart';
import 'package:makernote/screens/notes/note_screen.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/helpers/upload.helper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../utils/note_state.dart';
import '../controllers/editor.controller.dart';

class ExplanationElement extends HookWidget {
  const ExplanationElement({
    super.key,
    required this.explanationElement,
  });

  final ExplanationElementModel explanationElement;

  @override
  Widget build(BuildContext context) {
    var enabled = useState(false);
    final controller = Provider.of<EditorController?>(context);
    final stateWrapper = Provider.of<NoteScreenStateWrapper?>(context);
    final noteStack = Provider.of<NoteModelStack>(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Visibility(
        visible: <NoteScreenState>[
              NoteScreenState.editingTemplate,
            ].contains(stateWrapper?.state) ||
            (explanationElement.published &&
                !noteStack.template.hideExplanation),
        child: IgnorePointer(
          ignoring: controller != null &&
              controller.elementState.hashCode != explanationElement.hashCode,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              debugPrint('Explanation element tapped');
              enabled.value = true;

              if (noteStack.focusedNote == null) {
                debugPrint('No focused note');
                return;
              }

              // open explanation dialog
              await showExplanationDialog(
                context: context,
                explanationElement: explanationElement,
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
              color: explanationElement.published
                  ? Colors.black87
                  : Colors.grey.withAlpha(85),
              elevation: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !explanationElement.content.hasEmptyPath
                        ? Symbols.video_library
                        : FontAwesomeIcons.circleQuestion,
                    color: Theme.of(context).extension<CustomColors>()?.warning,
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

class ExplanationTitle extends HookWidget {
  const ExplanationTitle({
    super.key,
    required this.explanationElement,
    required this.controller,
  });

  final ExplanationElementModel explanationElement;
  final EditorController? controller;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(
      text: explanationElement.title,
    );
    final debouncer = useRef<Debouncer>(Debouncer(milliseconds: 300));
    if (controller == null) {
      return Text(
        explanationElement.title,
        style: Theme.of(context).textTheme.headlineMedium,
      );
    }

    useEffect(() {
      return () {
        debouncer.value.dispose();
      };
    }, [debouncer]);

    return TextField(
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      controller: textController,
      onChanged: (value) {
        explanationElement.updateWith(
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
    required this.explanationElement,
    required this.controller,
    required this.noteStack,
  });

  final String noteId;
  final ExplanationElementModel explanationElement;
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

          explanationElement.updateWith(
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
