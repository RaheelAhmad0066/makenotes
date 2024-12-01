import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/util/debuggers/graphic_element.debugger.dart';
import 'package:provider/provider.dart';

class EditorControllerDebugger extends HookWidget {
  const EditorControllerDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController?>(
      builder: (context, controller, child) {
        if (controller == null) return const SizedBox();
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withAlpha(169),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ExpansionTile(
            title: const Text('Editor Controller'),
            tilePadding: const EdgeInsets.all(8),
            childrenPadding: const EdgeInsets.all(8),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Editor Controller: ${controller.hashCode}'),
              Text('Command Driver Ref: ${controller.driver.hashCode}'),
              Text('Element Ref: ${controller.elementRef?.hashCode}'),
              Text('Element State: ${controller.elementState?.hashCode}'),
              Text('Element Index: ${controller.elementIndex}'),
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: controller.elementRef),
                ],
                builder: (context, child) {
                  return const GraphicElementDebugger();
                },
              )
            ],
          ),
        );
      },
    );
  }
}
