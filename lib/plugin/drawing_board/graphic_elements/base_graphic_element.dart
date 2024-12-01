// Base class composite on all graphic elements

import 'package:flutter/material.dart';
import '../models/graphic_element_model.dart';

class BaseGraphicElement extends StatelessWidget {
  const BaseGraphicElement({
    super.key,
    required this.graphicElement,
    this.child,
  });
  final GraphicElementModel graphicElement;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _buildGraphicElement(context);
  }

  _buildGraphicElement(BuildContext context) {
    return Visibility(
      visible: graphicElement.visibility,
      child: Opacity(
        opacity: graphicElement.opacity,
        child: Transform.rotate(
          angle: graphicElement.rotation,
          child: SizedBox(
            width: graphicElement.bounds.width,
            height: graphicElement.bounds.height,
            child: DecoratedBox(
              decoration: graphicElement.decoration,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
