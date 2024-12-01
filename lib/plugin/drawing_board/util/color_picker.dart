import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ColorPicker extends HookWidget {
  final Color pickerColor;
  final bool withTransparent;
  final void Function(Color) onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.withTransparent = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlockPicker(
      availableColors: [
        if (withTransparent) Colors.transparent,
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.lightBlue,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
        Colors.brown,
        Colors.grey,
        Colors.blueGrey,
        Colors.black,
        Colors.white,
      ],
      pickerColor: pickerColor,
      onColorChanged: onColorChanged,
      itemBuilder: (color, isCurrentColor, changeColor) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              changeColor();
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isCurrentColor
                      ? Theme.of(context).colorScheme.onBackground
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              width: 30,
              height: 30,
              child: color != Colors.transparent
                  ? null
                  : const Icon(
                      Icons.block,
                      color: Colors.red,
                    ),
            ),
          ),
        );
      },
    );
  }
}
