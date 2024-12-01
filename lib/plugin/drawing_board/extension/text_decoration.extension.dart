import 'package:flutter/material.dart';

extension TextDecorationExtension on TextDecoration {
  String toCustomString() {
    if (this == TextDecoration.none) return 'none';

    List<String> decorations = [];
    if (contains(TextDecoration.underline)) decorations.add('underline');
    if (contains(TextDecoration.overline)) decorations.add('overline');
    if (contains(TextDecoration.lineThrough)) decorations.add('lineThrough');

    return decorations.join(',');
  }

  static TextDecoration? fromCustomString(String? value) {
    if (value == null) return null;
    List<String> parts = value.split(',');
    List<TextDecoration> decorations = [];

    for (String part in parts) {
      switch (part) {
        case 'none':
          return TextDecoration.none;
        case 'underline':
          decorations.add(TextDecoration.underline);
          break;
        case 'overline':
          decorations.add(TextDecoration.overline);
          break;
        case 'lineThrough':
          decorations.add(TextDecoration.lineThrough);
          break;
        default:
          throw ArgumentError('Unknown TextDecoration string: $part');
      }
    }

    return TextDecoration.combine(decorations);
  }
}
