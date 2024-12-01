import 'package:flutter/material.dart';

extension FlexWithExtension on Flex {
  static Flex withSpacing({
    Key? key,
    Axis direction = Axis.horizontal,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Clip clipBehavior = Clip.none,
    List<Widget> children = const <Widget>[],
    double spacing = 0.0,
  }) {
    List<Widget> spacedChildren = children
        .map((child) => [
              child,
              SizedBox(
                width: direction == Axis.horizontal ? spacing : 12.0,
                height: direction == Axis.vertical ? spacing : 12.0,
              )
            ])
        .expand((element) => element)
        .toList();
    return Flex(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
      direction: direction,
      children: spacedChildren,
    );
  }
}
