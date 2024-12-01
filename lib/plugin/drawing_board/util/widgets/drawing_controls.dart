import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/graphic_elements/flutter_drawing_board_element.dart';
import 'package:makernote/plugin/drawing_board/util/color_picker.dart';
import 'package:makernote/plugin/drawing_board/util/commands/lib/update_drawingboard.command.dart';
import 'package:provider/provider.dart';

enum _DrawingControlsState {
  size,
  color,
}

class DrawingControls extends HookWidget {
  const DrawingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final drawingControllers =
        Provider.of<DrawingControllersProvider>(context, listen: true);
    final state = useState<_DrawingControlsState?>(null);

    if (drawingControllers.activeController == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        state.value = null;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // stroke size picker
          if (state.value == _DrawingControlsState.size)
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(0),
              child: SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ValueListenableBuilder(
                    valueListenable:
                        drawingControllers.activeController!.drawConfig,
                    builder: (context, value, child) {
                      return Slider(
                        value: drawingControllers.activeController?.drawConfig
                                .value.strokeWidth ??
                            1,
                        onChanged: (value) {
                          drawingControllers.activeController
                              ?.setStyle(strokeWidth: value);
                        },
                        min: 1,
                        max: 20,
                        divisions: 19,
                      );
                    },
                  ),
                ),
              ),
            ),

          // stroke color picker
          if (state.value == _DrawingControlsState.color)
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ColorPicker(
                  pickerColor: drawingControllers.activeController?.getColor ??
                      Colors.transparent,
                  onColorChanged: (color) {
                    drawingControllers.activeController?.setStyle(color: color);
                    state.value = null;
                  },
                ),
              ),
            ),

          const SizedBox(height: 10),

          // button bar
          Card(
            elevation: 6,
            margin: const EdgeInsets.all(0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  // undo button
                  _ControlIconButton(
                    onPressed: () {
                      drawingControllers.activeController?.undo();
                    },
                    icon: const Icon(Icons.undo),
                  ),
                  // redo button
                  _ControlIconButton(
                    onPressed: () {
                      drawingControllers.activeController?.redo();
                    },
                    icon: const Icon(Icons.redo),
                  ),

                  // Divider
                  const SizedBox(
                    width: 10,
                    height: 20,
                    child: VerticalDivider(),
                  ),

                  // pencil button
                  _ControlIconButton(
                    selected: drawingControllers
                        .activeController?.currentContent is SimpleLine,
                    onPressed: () {
                      drawingControllers.activeController?.setPaintContent(
                        SimpleLine(),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.pencil),
                  ),

                  // stroke size button
                  _ControlIconButton(
                    selected: state.value == _DrawingControlsState.size,
                    onPressed: () {
                      if (state.value == _DrawingControlsState.size) {
                        state.value = null;
                      } else {
                        state.value = _DrawingControlsState.size;
                      }
                    },
                    icon: const Icon(FontAwesomeIcons.circle),
                  ),

                  // color button
                  _ControlIconButton(
                    selected: state.value == _DrawingControlsState.color,
                    onPressed: () {
                      if (state.value == _DrawingControlsState.color) {
                        state.value = null;
                      } else {
                        state.value = _DrawingControlsState.color;
                      }
                    },
                    icon: const Icon(Icons.format_color_fill),
                  ),
                  // rubber button
                  _ControlIconButton(
                    onPressed: () {
                      drawingControllers.activeController?.setPaintContent(
                        Eraser(),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.eraser),
                  ),

                  // Divider
                  const SizedBox(
                    width: 10,
                    height: 20,
                    child: VerticalDivider(),
                  ),

                  // clear all button
                  // _ControlIconButton(
                  //   onPressed: () {
                  //     // show dialog
                  //     showDialog(
                  //       context: context,
                  //       builder: (context) {
                  //         return AlertDialog(
                  //           title: const Text('Clear all?'),
                  //           content: const Text(
                  //               'Are you sure you want to clear all drawings?'),
                  //           actions: [
                  //             TextButton(
                  //               onPressed: () {
                  //                 Navigator.of(context).pop();
                  //               },
                  //               child: const Text('Cancel'),
                  //             ),
                  //             TextButton(
                  //               onPressed: () {
                  //                 drawingControllers.activeController?.clear();
                  //                 Navigator.of(context).pop();
                  //               },
                  //               child: const Text('Clear'),
                  //             ),
                  //           ],
                  //         );
                  //       },
                  //     );
                  //   },
                  //   icon: const Icon(Icons.clear),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlIconButton extends HookWidget {
  const _ControlIconButton({
    this.selected = false,
    required this.icon,
    this.onPressed,
  });

  final bool selected;
  final Icon icon;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: selected
                ? Theme.of(context).colorScheme.onBackground.withAlpha(64)
                : Colors.transparent,
          ),
          child: icon,
        ),
      ),
    );
  }
}
