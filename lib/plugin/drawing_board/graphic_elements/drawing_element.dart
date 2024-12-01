import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/drawing_element_model.dart';
import '../util/sketch.dart';
import 'base_graphic_element.dart';

class DrawingElement extends HookWidget {
  DrawingElement({
    super.key,
    required this.drawingElement,
    this.enabled = false,
    this.penSize = 10,
    this.penColor = Colors.black,
    this.onSketchCreated,
    Size? canvasSize,
  }) {
    if (canvasSize == null) return;
    drawingElement.bounds =
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
  }

  final DrawingElementModel drawingElement;

  final bool enabled;
  final double penSize;
  final Color penColor;

  // callback when a sketch is created
  final void Function(Sketch, DrawingElementModel)? onSketchCreated;

  @override
  Widget build(BuildContext context) {
    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState(drawingElement.sketches);

    final onPanStart = useCallback<void Function(DragStartDetails)>(
        (DragStartDetails details) {
      currentSketch.value = Sketch(
        points: [details.localPosition],
        size: penSize,
        color: penColor,
      );
    }, [currentSketch, penSize, penColor]);

    final onPanUpdate = useCallback<void Function(DragUpdateDetails)>(
        (DragUpdateDetails details) {
      currentSketch.value = Sketch(
        points: [...currentSketch.value!.points, details.localPosition],
        size: penSize,
        color: penColor,
      );
    }, [currentSketch, penSize, penColor]);

    final onPanEnd =
        useCallback<void Function(DragEndDetails)>((DragEndDetails details) {
      if (currentSketch.value == null) return;
      allSketches.value = [...allSketches.value, currentSketch.value!];
      drawingElement.sketches.add(currentSketch.value!);

      onSketchCreated?.call(currentSketch.value!, drawingElement);

      currentSketch.value = null;
    }, [currentSketch, allSketches]);

    return Stack(
      children: [
        // draw all the sketches
        Positioned.fromRect(
          rect: drawingElement.bounds,
          child: BaseGraphicElement(
            graphicElement: drawingElement,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DrawingPainter(
                    sketches: allSketches.value,
                  ),
                ),
              ),
            ),
          ),
        ),
        // draw the current sketch
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: AbsorbPointer(
            absorbing: !enabled,
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: ValueListenableBuilder(
                valueListenable: currentSketch,
                builder: (context, sketch, child) => ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _DrawingPainter(
                        sketches: sketch == null ? [] : [currentSketch.value],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({
    required this.sketches,
  });

  final List<Sketch?> sketches;

  void _paintSketch(Canvas canvas, Sketch? sketch) {
    Paint paint = Paint()
      ..color = sketch!.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = sketch.size;

    for (int i = 0; i < sketch.points.length - 1; i++) {
      if (sketch.points[i] != null && sketch.points[i + 1] != null) {
        // reduce the stroke width smoothly by the distance between the two points,
        // so that the line is thinner when the points are further apart
        // min size is 10% of the original size
        double distance = (sketch.points[i]! - sketch.points[i + 1]!).distance;
        double size = sketch.size * (10.0 / (10.0 + distance));
        size = size < sketch.size * 0.1 ? sketch.size * 0.1 : size;
        paint.strokeWidth = size;

        canvas.drawLine(sketch.points[i]!, sketch.points[i + 1]!, paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final sketch in sketches) {
      if (sketch != null) {
        _paintSketch(canvas, sketch);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }
}
