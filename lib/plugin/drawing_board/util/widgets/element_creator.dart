import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/graphic_elements/base_graphic_element.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/image_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/text_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/drawing_mode.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/helpers/upload.helper.dart';
import 'package:provider/provider.dart';

import '../../models/explanation_element_model.dart';
import '../../models/video_element_model.dart';

class EditorCreator extends HookWidget {
  final void Function(GraphicElementModel)? onCreated;
  final void Function()? onCancel;

  const EditorCreator({
    super.key,
    this.onCreated,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    var startingPoint = useState<Offset?>(null);
    var currentPoint = useState<Offset?>(null);
    var graphicElement = useState<GraphicElementModel?>(null);

    var handleCreate = useCallback(() async {
      final controller =
          Provider.of<DrawingBoardController>(context, listen: false);
      if (<DrawingMode>[
        DrawingMode.pointer,
        DrawingMode.pencil,
        DrawingMode.eraser,
      ].contains(controller.drawingMode)) {
        return;
      }

      GraphicElementModel? newElement;

      // create polygon
      if (controller.drawingMode == DrawingMode.polygon) {
        var rect = graphicElement.value?.bounds ?? Rect.zero;
        // if the rect is too small, don't create a new element
        if (rect.width < 10 || rect.height < 10) {
          rect = Rect.fromLTWH(
            rect.left,
            rect.top,
            100,
            100,
          );
        }
        newElement = graphicElement.value?.copyWith(
          bounds: rect,
        );
      }

      // create text
      if (controller.drawingMode == DrawingMode.text) {
        newElement = TextElementModel(
          bounds: Rect.fromPoints(currentPoint.value!, currentPoint.value!),
          decoration: const BoxDecoration(color: Colors.transparent),
          opacity: 1.0,
          visibility: true,
          text: 'Text Element',
          textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        );
      }

      // create image
      if (controller.drawingMode == DrawingMode.image) {
        try {
          if (context.mounted) {
            final url = await showPickFileDialog(
                context: context,
                fileType: FileType.image,
                prefix: Provider.of<NoteModelStack>(context, listen: false)
                    .focusedNote
                    ?.id);
            if (url == null) {
              return;
            }
            newElement = ImageElementModel(
              bounds: Rect.fromLTWH(
                currentPoint.value!.dx,
                currentPoint.value!.dy,
                100,
                100,
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
              opacity: 1.0,
              visibility: true,
              url: url,
            );
          }
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      // create video
      if (controller.drawingMode == DrawingMode.video) {
        try {
          if (context.mounted) {
            final url = await showPickFileDialog(
                context: context,
                fileType: FileType.video,
                prefix: Provider.of<NoteModelStack>(context, listen: false)
                    .focusedNote
                    ?.id);
            if (url == null) {
              return;
            }
            newElement = VideoElementModel(
              bounds: Rect.fromLTWH(
                currentPoint.value!.dx,
                currentPoint.value!.dy,
                100,
                100,
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
              opacity: 1.0,
              visibility: true,
              title: 'Video Title',
              content: Uri.parse(url),
            );
          }
        } catch (e) {
          debugPrint('Error uploading video: $e');
        }
      }

      // create explanation
      if (controller.drawingMode == DrawingMode.explanation) {
        newElement = ExplanationElementModel(
          bounds: Rect.fromLTWH(
            currentPoint.value!.dx,
            currentPoint.value!.dy,
            50,
            50,
          ),
          decoration: const BoxDecoration(color: Colors.transparent),
          opacity: 1.0,
          visibility: true,
          title: 'Explanation Title',
          // empty uri
          content: Uri.parse(''),
        );
      }

      if (newElement != null) {
        debugPrint('Created new element: $newElement');
        controller.drawingMode = DrawingMode.pointer;
        onCreated?.call(newElement);
      } else {
        debugPrint('No new element created');
        onCancel?.call();
      }
      graphicElement.value = null;
    }, [
      startingPoint,
      currentPoint,
      graphicElement,
    ]);
    return Consumer<DrawingBoardController>(
      builder: (context, controller, child) {
        if (<DrawingMode>[
          DrawingMode.pointer,
          DrawingMode.pencil,
          DrawingMode.eraser,
        ].contains(controller.drawingMode)) {
          return const SizedBox();
        } else {
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                startingPoint.value = details.localPosition;
              },
              onTapUp: (details) {
                currentPoint.value = details.localPosition;
                handleCreate();
              },
              onPanStart: (details) {
                startingPoint.value = details.localPosition;
                currentPoint.value = details.localPosition;
                graphicElement.value = GraphicElementModel(
                  bounds: Rect.fromPoints(
                      startingPoint.value!, currentPoint.value!),
                  decoration: BoxDecoration(
                      color: controller.drawingMode == DrawingMode.polygon
                          ? Theme.of(context).extension<CustomColors>()?.dimmed
                          : Colors.transparent),
                  opacity: 1.0,
                  visibility: true,
                );
              },
              onPanUpdate: (details) {
                currentPoint.value = details.localPosition;
                graphicElement.value = graphicElement.value!.copyWith(
                  bounds: Rect.fromPoints(
                      startingPoint.value!, currentPoint.value!),
                );
              },
              onPanEnd: (details) {
                handleCreate();
              },
              child: graphicElement.value != null
                  ? Stack(
                      children: [
                        Positioned.fromRect(
                          rect: graphicElement.value!.bounds,
                          child: BaseGraphicElement(
                            graphicElement: graphicElement.value!,
                          ),
                        )
                      ],
                    )
                  : null,
            ),
          );
        }
      },
    );
  }
}
