import 'package:flutter/material.dart';

class SingleLineBackgroundPainter extends CustomPainter {
  SingleLineBackgroundPainter({
    this.lineThickness = 2.0,
    this.lineSpacing = 20.0,
    this.padding = EdgeInsets.zero,
  });

  final double lineThickness;
  final double lineSpacing;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = lineThickness;

    double y = padding.top;
    while (y < size.height - padding.bottom) {
      final startPoint = Offset(padding.left, y);
      final endPoint = Offset(size.width - padding.right, y);
      canvas.drawLine(startPoint, endPoint, paint);

      y += lineSpacing + lineThickness;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
