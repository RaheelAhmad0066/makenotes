import 'package:flutter/material.dart';

Color? lerpThreeColors(Color? a, Color? b, Color? c, double? t) {
  // null check
  if (a == null || b == null || c == null) {
    return null;
  }
  t ??= 0;
  if (t < 0.5) {
    return Color.lerp(a, b, t * 2)!;
  } else {
    return Color.lerp(b, c, (t - 0.5) * 2)!;
  }
}
