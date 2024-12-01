import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/drawing_mode.dart';
import 'package:provider/provider.dart';

class EditorHint extends HookWidget {
  const EditorHint({super.key});

  String? getHintText(DrawingMode mode) {
    switch (mode) {
      case DrawingMode.text:
        return 'Tap to place text';
      case DrawingMode.image:
        return 'Tap to place image';
      case DrawingMode.video:
        return 'Tap to place video';
      case DrawingMode.polygon:
        return 'Tap to place rectangle';
      case DrawingMode.explanation:
        return 'Tap to place explanation';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingBoardController = Provider.of<DrawingBoardController>(context);

    return Selector<EditorController?, GraphicElementModel?>(
      selector: (context, controller) => controller?.elementState,
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      builder: (context, element, child) {
        if (element != null) {
          return const SizedBox();
        }

        final text = getHintText(drawingBoardController.drawingMode);

        if (text == null) {
          return const SizedBox();
        }

        return Card(
          elevation: 6,
          margin: const EdgeInsets.all(0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
