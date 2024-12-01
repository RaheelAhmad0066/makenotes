import 'package:flutter/material.dart';

class Sketch {
  Sketch({
    required this.points,
    required this.size,
    required this.color,
  });

  final List<Offset?> points;
  final double size;
  final Color color;
}
