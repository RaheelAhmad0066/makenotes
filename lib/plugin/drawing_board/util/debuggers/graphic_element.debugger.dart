import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/image_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/scribble_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/text_element_model.dart';
import 'package:provider/provider.dart';

import '../../models/explanation_element_model.dart';
import '../../models/video_element_model.dart';

class GraphicElementDebugger extends HookWidget {
  const GraphicElementDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphicElementModel?>(
      builder: (context, element, child) {
        if (element == null) return const SizedBox();
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.secondaryContainer.withAlpha(85),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(8),
            childrenPadding: const EdgeInsets.all(8),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text('Element ${element.hashCode}'),
            children: [
              Text('Element Type: ${element.type}'),
              Text('Element Bounds: ${element.bounds}'),
              Text('Element Decoration: ${element.decoration}'),
              Text('Element Opacity: ${element.opacity}'),
              ...switch (element.type) {
                GraphicElementType.text => element is TextElementModel
                    ? [
                        Text('Element Text: ${element.text}'),
                        Text('Element Text Style: ${element.textStyle}'),
                      ]
                    : [],
                GraphicElementType.rectangle => [],
                GraphicElementType.drawing => element is ScribbleElementModel
                    ? [
                        Text('Element Lines: ${element.sketch.lines.length}'),
                      ]
                    : [],
                GraphicElementType.image => element is ImageElementModel
                    ? [
                        Text('Element Image: ${element.url}'),
                      ]
                    : [],
                GraphicElementType.video => element is VideoElementModel
                    ? [
                        Text('Element Title: ${element.title}'),
                        Text('Element Video: ${element.content}'),
                      ]
                    : [],
                GraphicElementType.explanation =>
                  element is ExplanationElementModel
                      ? [
                          Text('Element Title: ${element.title}'),
                          Text('Element Content: ${element.content}'),
                        ]
                      : [],
              }
            ],
          ),
        );
      },
    );
  }
}
