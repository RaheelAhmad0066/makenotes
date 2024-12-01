import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:provider/provider.dart';

class ZoomControls extends HookWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingBoardController>(
      builder: (context, controller, child) {
        return Row(
          children: [
            // IconButton.filled(
            //   tooltip: 'Zoom In',
            //   onPressed: () {
            //     controller.zoomIn();
            //   },
            //   icon: const Icon(Icons.zoom_in),
            // ),
            GestureDetector(
              onDoubleTap: () {
                debugPrint('double tap');
                controller.zoomReset(resetTranslation: true);
              },
              child: ElevatedButton(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                ),
                onPressed: () {
                  debugPrint('single tap');
                },
                onLongPress: () {
                  debugPrint('long press');
                },
                child: Text(
                  '${(controller.currentScale * 100).toStringAsFixed(0)}%',
                ),
              ),
            ),
            // IconButton.filled(
            //   tooltip: 'Zoom Out',
            //   onPressed: () {
            //     controller.zoomOut();
            //   },
            //   icon: const Icon(Icons.zoom_out),
            // ),
          ],
        );
      },
    );
  }
}
