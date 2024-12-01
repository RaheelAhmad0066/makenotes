import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/color_picker.dart';
import 'package:makernote/plugin/drawing_board/util/commands/lib/delete.command.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:provider/provider.dart';

import '../../models/text_element_model.dart';

enum _EditorState {
  opacity,
  backgroundColor,
}

class EditorControls extends HookWidget {
  const EditorControls({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<_EditorState?>(null);
    return Selector<EditorController?, GraphicElementModel?>(
      selector: (context, controller) => controller?.elementState,
      shouldRebuild: (previous, next) {
        // post frame callback to clear state
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          state.value = null;
        });
        return previous != next;
      },
      builder: (context, element, child) {
        if (element == null) {
          return const SizedBox();
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (state.value == _EditorState.opacity)
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(0),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(4),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      trackShape: const RectangularSliderTrackShape(),
                      thumbShape: const RoundSliderThumbShape(
                          disabledThumbRadius: 10, enabledThumbRadius: 10),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 15),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      onChanged: (value) {
                        element.updateWith(
                          opacity: value,
                        );
                        final controller = Provider.of<EditorController>(
                            context,
                            listen: false);
                        controller.updateStateToRef();
                      },
                      divisions: 10,
                      value: element.opacity,
                    ),
                  ),
                ),
              ),

            if (state.value == _EditorState.backgroundColor)
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ColorPicker(
                    pickerColor: element.decoration.color ?? Colors.transparent,
                    onColorChanged: (color) {
                      element.updateWith(
                        decoration: element.decoration.copyWith(color: color),
                      );
                      final controller =
                          Provider.of<EditorController>(context, listen: false);
                      controller.updateStateToRef();
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
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (context) => TextEditingController(
                          text: element is TextElementModel
                              ? element.textStyle.fontSize.toString()
                              : ''),
                    ),
                  ],
                  builder: (context, child) {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        if (<GraphicElementType>[
                          GraphicElementType.image,
                          GraphicElementType.video,
                          GraphicElementType.text,
                          GraphicElementType.rectangle,
                        ].contains(element.type)) ...[
                          // visibility button
                          Selector<EditorController, bool>(
                            selector: (context, controller) =>
                                element.visibility,
                            builder: (context, visibility, child) =>
                                _ControlIconButton(
                              onPressed: () {
                                element.updateWith(
                                  visibility: !element.visibility,
                                );
                                final controller =
                                    Provider.of<EditorController>(context,
                                        listen: false);
                                controller.updateStateToRef();
                              },
                              icon: Icon(
                                element.visibility
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),

                          // opacity menu button
                          _ControlIconButton(
                            onPressed: () {
                              state.value = state.value == _EditorState.opacity
                                  ? null
                                  : _EditorState.opacity;
                            },
                            icon: const Icon(Icons.opacity),
                          ),

                          // background color menu button
                          _ControlIconButton(
                            onPressed: () {
                              state.value =
                                  state.value == _EditorState.backgroundColor
                                      ? null
                                      : _EditorState.backgroundColor;
                            },
                            icon: Icon(
                              Icons.format_color_fill,
                              color:
                                  element.decoration.color != Colors.transparent
                                      ? element.decoration.color
                                      : null,
                            ),
                          ),
                        ],

                        // extra tools
                        ...extraTools(context),

                        const SizedBox(
                          width: 10,
                          height: 20,
                          child: VerticalDivider(),
                        ),

                        // delete button
                        _ControlIconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context)
                                .extension<CustomColors>()
                                ?.dimmed,
                          ),
                          onPressed: () {
                            final controller = Provider.of<EditorController>(
                                context,
                                listen: false);
                            controller.driver.execute(
                              DeleteCommand(
                                elementIndex: controller.elementIndex!,
                                pageService: controller.editorPageService,
                                pageModel: controller.pageModel,
                              ),
                            );

                            controller.clearElement();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> extraTools(BuildContext context) {
    final controller = Provider.of<EditorController>(context, listen: false);
    if (!controller.hasElement) return [];
    return switch (controller.elementState!.type) {
      GraphicElementType.drawing => [],
      GraphicElementType.image => [],
      GraphicElementType.video => [],
      GraphicElementType.rectangle => [],
      GraphicElementType.text => [
          const TextTools(),
        ],
      GraphicElementType.explanation => [
          const ExplanationTools(),
        ],
    };
  }
}

class ExplanationTools extends HookWidget {
  const ExplanationTools({super.key});

  @override
  Widget build(BuildContext context) {
    final debouncer = useRef<Debouncer>(Debouncer(milliseconds: 300));
    final controller = Provider.of<EditorController>(context);

    useEffect(() {
      return () {
        debouncer.value.dispose();
      };
    }, [debouncer]);

    return ChangeNotifierProvider.value(
      value: controller.elementState! as ExplanationElementModel,
      builder: (context, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            const SizedBox(
              width: 10,
              height: 20,
              child: VerticalDivider(),
            ),

            // published toggle
            Selector<ExplanationElementModel, bool>(
              selector: (context, explanation) => explanation.published,
              builder: (context, published, child) {
                return Tooltip(
                  message: published ? 'Published' : 'Not published',
                  child: _ControlIconButton(
                    onPressed: () {
                      var explanationElement =
                          controller.elementState as ExplanationElementModel;
                      explanationElement.updateWith(
                        published: !explanationElement.published,
                      );

                      debouncer.value.run(() {
                        controller.updateStateToRef();
                      });
                    },
                    icon: Icon(
                      published ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class TextTools extends HookWidget {
  const TextTools({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    return ChangeNotifierProvider.value(
      value: controller.elementState! as TextElementModel,
      builder: (context, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            const SizedBox(
              width: 10,
              height: 20,
              child: VerticalDivider(),
            ),

            const _FontSizeTools(),

            // Text color
            Selector<TextElementModel, Color>(
              selector: (context, text) => text.textStyle.color ?? Colors.black,
              builder: (context, color, child) {
                return _ControlIconButton(
                  onPressed: () async {
                    var textElement =
                        controller.elementState as TextElementModel;
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Pick a color!'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor:
                                  textElement.textStyle.color ?? Colors.black,
                              onColorChanged: (color) {
                                Navigator.of(context).pop(color);
                              },
                            ),
                          ),
                        );
                      },
                    );
                    if (color != null) {
                      textElement.updateWith(
                        textStyle: textElement.textStyle.copyWith(
                          fontSize: textElement.textStyle.fontSize,
                          color: color,
                        ),
                      );

                      controller.updateStateToRef();
                    }
                  },
                  icon: Icon(
                    Icons.format_color_text,
                    color: color,
                  ),
                );
              },
            ),

            // text bold toggle
            Selector<TextElementModel, TextStyle>(
              selector: (context, text) => text.textStyle,
              builder: (context, textStyle, child) {
                return _ControlIconButton(
                  selected: textStyle.fontWeight == FontWeight.bold,
                  onPressed: () {
                    var textElement =
                        controller.elementState as TextElementModel;
                    textElement.updateWith(
                      textStyle: textElement.textStyle.copyWith(
                        fontSize: textElement.textStyle.fontSize,
                        fontWeight:
                            textElement.textStyle.fontWeight == FontWeight.bold
                                ? FontWeight.normal
                                : FontWeight.bold,
                        color: textElement.textStyle.color,
                      ),
                    );

                    controller.updateStateToRef();
                  },
                  icon: const Icon(
                    Icons.format_bold,
                  ),
                );
              },
            ),

            // text italic toggle
            Selector<TextElementModel, TextStyle>(
              selector: (context, text) => text.textStyle,
              builder: (context, textStyle, child) {
                return _ControlIconButton(
                  selected: textStyle.fontStyle == FontStyle.italic,
                  onPressed: () {
                    var textElement =
                        controller.elementState as TextElementModel;
                    textElement.updateWith(
                      textStyle: textElement.textStyle.copyWith(
                        fontSize: textElement.textStyle.fontSize,
                        fontStyle:
                            textElement.textStyle.fontStyle == FontStyle.italic
                                ? FontStyle.normal
                                : FontStyle.italic,
                        color: textElement.textStyle.color,
                      ),
                    );

                    controller.updateStateToRef();
                  },
                  icon: const Icon(
                    Icons.format_italic,
                  ),
                );
              },
            ),

            // text underline toggle
            Selector<TextElementModel, TextStyle>(
              selector: (context, text) => text.textStyle,
              builder: (context, textStyle, child) {
                return _ControlIconButton(
                  selected: textStyle.decoration == TextDecoration.underline,
                  onPressed: () {
                    var textElement =
                        controller.elementState as TextElementModel;
                    textElement.updateWith(
                      textStyle: textElement.textStyle.copyWith(
                        fontSize: textElement.textStyle.fontSize,
                        decoration: textElement.textStyle.decoration ==
                                TextDecoration.underline
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        color: textElement.textStyle.color,
                      ),
                    );

                    controller.updateStateToRef();
                  },
                  icon: const Icon(
                    Icons.format_underline,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FontSizeTools extends HookWidget {
  const _FontSizeTools();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final textElement = controller.elementState as TextElementModel;
    final tController = useTextEditingController(
      text: textElement.textStyle.fontSize.toString(),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        _ControlIconButton(
          onPressed: () {
            textElement.updateWith(
              textStyle: textElement.textStyle.copyWith(
                fontSize: textElement.textStyle.fontSize! - 1,
                color: textElement.textStyle.color,
              ),
            );
            tController.text = textElement.textStyle.fontSize.toString();

            controller.updateStateToRef();
          },
          icon: const Icon(
            Icons.remove,
          ),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: tController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            onChanged: (value) {
              if (value.isEmpty) return;

              final size = max<int>(int.tryParse(value) ?? 1, 1);

              textElement.updateWith(
                textStyle: textElement.textStyle.copyWith(
                  fontSize: size.toDouble(),
                  color: textElement.textStyle.color,
                ),
              );

              controller.updateStateToRef();
            },
          ),
        ),
        _ControlIconButton(
          onPressed: () {
            textElement.updateWith(
              textStyle: textElement.textStyle.copyWith(
                fontSize: textElement.textStyle.fontSize! + 1,
                color: textElement.textStyle.color,
              ),
            );
            tController.text = textElement.textStyle.fontSize.toString();

            controller.updateStateToRef();
          },
          icon: const Icon(
            Icons.add,
          ),
        ),
      ],
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
