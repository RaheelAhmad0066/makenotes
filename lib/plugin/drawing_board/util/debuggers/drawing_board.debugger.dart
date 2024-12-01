import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:provider/provider.dart';

class DrawingBoardDebugger extends HookWidget {
  const DrawingBoardDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingBoardController?>(
      builder: (context, controller, child) {
        if (controller == null) return const SizedBox();
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withAlpha(169),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ExpansionTile(
            title: const Text('Drawing Board Controller'),
            tilePadding: const EdgeInsets.all(8),
            childrenPadding: const EdgeInsets.all(8),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Drawing Board Controller: ${controller.hashCode}'),
              Text('Drawing Mode: ${controller.drawingMode}'),
              Text('Pen Size: ${controller.penSize}'),
              Text('Pen Color: ${controller.penColor}'),
              Text('Text Style: ${controller.textStyle}'),
              Text('Current Scale: ${controller.currentScale}'),
              Text('Exponent: ${controller.exponent}'),
            ],
          ),
        );
      },
    );
  }
}
