import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/graphic_element_model.dart';

import 'base_graphic_element.dart';

class FullsizeGraphicElement extends HookWidget {
  FullsizeGraphicElement({
    super.key,
    this.child,
    required this.graphicElement,
    required Size canvasSize,
  }) {
    graphicElement.bounds =
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
  }

  final GraphicElementModel graphicElement;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      return () {
        graphicElement.dispose();
      };
    }, [graphicElement]);

    return Positioned.fromRect(
      rect: graphicElement.bounds,
      child: BaseGraphicElement(
        graphicElement: graphicElement,
        child: child,
      ),
    );
  }
}
