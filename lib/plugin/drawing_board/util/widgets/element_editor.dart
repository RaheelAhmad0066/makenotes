import 'dart:math';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/graphic_elements/base_graphic_element.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:provider/provider.dart';

enum DragHandle {
  move,
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomRight,
  bottomLeft,
}

class ElementEditor extends HookWidget {
  final double scale;

  final strokeWidth = 2.0;
  final controlSize = 12.0;

  final Offset controlsOffset = const Offset(50, 50);

  // callback on element edit start
  final void Function(GraphicElementModel element)? onEditStart;

  // callback on element edit end
  final void Function(GraphicElementModel element)? onEditEnd;

  const ElementEditor({
    super.key,
    this.scale = 1.0,
    this.onEditStart,
    this.onEditEnd,
  });

  double _calculateAngle(Offset center, Offset touchPoint) {
    return (touchPoint - center).direction;
  }

  @override
  Widget build(BuildContext context) {
    var pageModel = Provider.of<PageModel?>(context);
    if (pageModel == null) {
      throw Exception('No page model found');
    }

    final editorController = Provider.of<EditorController>(context);
    final editingElement = Provider.of<GraphicElementModel>(context);

    useEffect(() {
      debugPrint(
          'element editor rendering - element ref: ${editorController.elementRef.hashCode} - state: ${editingElement.hashCode}');
      return () {
        debugPrint('element editor unmounting');
      };
    }, [editorController.elementState]);

    var onEditStart = useCallback(() {
      debugPrint('on edit start');
      this.onEditStart?.call(
            editingElement,
          );
    }, [
      this.onEditStart,
      editingElement,
    ]);

    var onEditEnd = useCallback(() {
      debugPrint('on edit end');
      editorController.updateStateToRef();
      this.onEditEnd?.call(
            editingElement,
          );
    }, [
      this.onEditEnd,
      editingElement,
    ]);
    final handleDrag =
        useCallback((DragUpdateDetails details, DragHandle handle) {
      Offset topLeftDelta = const Offset(0, 0);
      Offset bottomRightDelta = const Offset(0, 0);

      switch (handle) {
        case DragHandle.move:
          topLeftDelta = details.delta;
          bottomRightDelta = details.delta;
          break;
        case DragHandle.top:
          topLeftDelta = Offset(0, details.delta.dy);
          break;
        case DragHandle.bottom:
          bottomRightDelta = Offset(0, details.delta.dy);
          break;
        case DragHandle.left:
          topLeftDelta = Offset(details.delta.dx, 0);
          break;
        case DragHandle.right:
          bottomRightDelta = Offset(details.delta.dx, 0);
          break;
        case DragHandle.topLeft:
          topLeftDelta = details.delta;
          break;
        case DragHandle.topRight:
          topLeftDelta = Offset(0, details.delta.dy);
          bottomRightDelta = Offset(details.delta.dx, 0);
          break;
        case DragHandle.bottomRight:
          bottomRightDelta = details.delta;
          break;
        case DragHandle.bottomLeft:
          topLeftDelta = Offset(details.delta.dx, 0);
          bottomRightDelta = Offset(0, details.delta.dy);
          break;
      }

      final newBounds = Rect.fromPoints(
        editingElement.bounds.topLeft + topLeftDelta,
        editingElement.bounds.bottomRight + bottomRightDelta,
      );
      editingElement.updateWith(bounds: newBounds);
    }, [editingElement]);

    final handleRotate = useCallback((double angle) {
      editingElement.updateWith(rotation: angle);
    }, [editingElement]);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: editingElement.bounds,
          child: GestureDetector(
            onPanStart: (details) {
              onEditStart.call();
            },
            onPanEnd: (details) {
              onEditEnd.call();
            },
            onPanUpdate: (details) => handleDrag(details, DragHandle.move),
            child: BaseGraphicElement(
              graphicElement: editingElement,
              child: GraphicElementModel.getElementWidget(
                element: editingElement,
              ),
            ),
          ),
        ),

        // controls
        Positioned(
          // with 50 offset
          top: editingElement.bounds.top - controlsOffset.dy / scale,
          left: editingElement.bounds.left - controlsOffset.dx / scale,
          width: editingElement.bounds.width + controlsOffset.dx / scale * 2,
          height: editingElement.bounds.height + controlsOffset.dy / scale * 2,
          child: Transform.rotate(
            angle: editingElement.rotation,
            child: Stack(
              children: [
                // dotted edges
                // top edge
                Positioned(
                  top: controlsOffset.dy / scale - controlSize / scale / 2,
                  left: controlsOffset.dx / scale,
                  height: controlSize / scale,
                  width: editingElement.bounds.width,
                  child: GestureDetector(
                    onPanStart: (details) {
                      onEditStart.call();
                    },
                    onPanEnd: (details) {
                      onEditEnd.call();
                    },
                    onPanUpdate: (details) =>
                        handleDrag(details, DragHandle.top),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUp,
                      child: Center(
                        child: DottedLine(
                          direction: Axis.horizontal,
                          lineThickness: strokeWidth / scale,
                          dashLength: controlSize / scale / 2,
                          dashColor: Colors.blueAccent,
                          dashGapLength: controlSize / scale / 2,
                          dashGapColor: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),
                // bottom edge
                Positioned(
                  top: editingElement.bounds.height +
                      controlsOffset.dy / scale -
                      controlSize / scale / 2,
                  left: controlsOffset.dx / scale,
                  height: controlSize / scale,
                  width: editingElement.bounds.width,
                  child: GestureDetector(
                    onPanStart: (details) {
                      onEditStart.call();
                    },
                    onPanEnd: (details) {
                      onEditEnd.call();
                    },
                    onPanUpdate: (details) =>
                        handleDrag(details, DragHandle.bottom),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeDown,
                      child: Center(
                        child: DottedLine(
                          direction: Axis.horizontal,
                          lineThickness: strokeWidth / scale,
                          dashLength: controlSize / scale / 2,
                          dashColor: Colors.blueAccent,
                          dashGapLength: controlSize / scale / 2,
                          dashGapColor: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),
                // left edge
                Positioned(
                  top: controlsOffset.dy / scale,
                  left: controlsOffset.dx / scale - controlSize / scale / 2,
                  height: editingElement.bounds.height,
                  width: controlSize / scale,
                  child: GestureDetector(
                    onPanStart: (details) {
                      onEditStart.call();
                    },
                    onPanEnd: (details) {
                      onEditEnd.call();
                    },
                    onPanUpdate: (details) =>
                        handleDrag(details, DragHandle.left),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeft,
                      child: Center(
                        child: DottedLine(
                          direction: Axis.vertical,
                          lineThickness: strokeWidth / scale,
                          dashLength: controlSize / scale / 2,
                          dashColor: Colors.blueAccent,
                          dashGapLength: controlSize / scale / 2,
                          dashGapColor: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),
                // right edge
                Positioned(
                  top: controlsOffset.dy / scale,
                  left: editingElement.bounds.width +
                      controlsOffset.dx / scale -
                      controlSize / scale / 2,
                  height: editingElement.bounds.height,
                  width: controlSize / scale,
                  child: GestureDetector(
                    onPanStart: (details) {
                      onEditStart.call();
                    },
                    onPanEnd: (details) {
                      onEditEnd.call();
                    },
                    onPanUpdate: (details) =>
                        handleDrag(details, DragHandle.right),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeRight,
                      child: Center(
                        child: DottedLine(
                          direction: Axis.vertical,
                          lineThickness: strokeWidth / scale,
                          dashLength: controlSize / scale / 2,
                          dashColor: Colors.blueAccent,
                          dashGapLength: controlSize / scale / 2,
                          dashGapColor: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top-left box
                _anchorBox(
                  top: controlsOffset.dy / scale -
                      controlSize / scale / 2 +
                      strokeWidth / scale / 2,
                  left: controlsOffset.dx / scale -
                      controlSize / scale / 2 +
                      strokeWidth / scale / 2,
                  onDragStart: (details) {
                    onEditStart.call();
                  },
                  onDragEnd: (details) {
                    onEditEnd.call();
                  },
                  handleDrag: (details) =>
                      handleDrag(details, DragHandle.topLeft),
                  cursor: SystemMouseCursors.resizeUpLeft,
                ),
                // Top-right box
                _anchorBox(
                  top: controlsOffset.dy / scale -
                      controlSize / scale / 2 +
                      strokeWidth / scale / 2,
                  left: editingElement.bounds.width +
                      controlsOffset.dx / scale -
                      controlSize / scale / 2 -
                      strokeWidth / scale / 2,
                  onDragStart: (details) {
                    onEditStart.call();
                  },
                  onDragEnd: (details) {
                    onEditEnd.call();
                  },
                  handleDrag: (details) =>
                      handleDrag(details, DragHandle.topRight),
                  cursor: SystemMouseCursors.resizeUpRight,
                ),
                // Bottom-right box
                _anchorBox(
                  top: editingElement.bounds.height +
                      controlsOffset.dy / scale -
                      controlSize / scale / 2 -
                      strokeWidth / scale / 2,
                  left: editingElement.bounds.width +
                      controlsOffset.dx / scale -
                      controlSize / scale / 2 -
                      strokeWidth / scale / 2,
                  onDragStart: (details) {
                    onEditStart.call();
                  },
                  onDragEnd: (details) {
                    onEditEnd.call();
                  },
                  handleDrag: (details) =>
                      handleDrag(details, DragHandle.bottomRight),
                  cursor: SystemMouseCursors.resizeDownRight,
                ),
                // Bottom-left box
                _anchorBox(
                  top: editingElement.bounds.height +
                      controlsOffset.dy / scale -
                      controlSize / scale / 2 -
                      strokeWidth / scale / 2,
                  left: controlsOffset.dx / scale -
                      controlSize / scale / 2 +
                      strokeWidth / scale / 2,
                  onDragStart: (details) {
                    onEditStart.call();
                  },
                  onDragEnd: (details) {
                    onEditEnd.call();
                  },
                  handleDrag: (details) =>
                      handleDrag(details, DragHandle.bottomLeft),
                  cursor: SystemMouseCursors.resizeDownLeft,
                ),

                // Rotation handle
                Positioned(
                  top: controlsOffset.dy / scale -
                      (controlSize + 10) / scale -
                      20,
                  left: controlsOffset.dx / scale +
                      (editingElement.bounds.right -
                              editingElement.bounds.left) /
                          2 -
                      (controlSize + 10) / scale / 2,
                  child: GestureDetector(
                    onPanStart: (details) {
                      onEditStart.call();
                    },
                    onPanUpdate: (details) {
                      final center = editingElement.bounds.center;
                      final currentTouchPoint = Offset(
                          details.globalPosition.dx,
                          details.globalPosition.dy - kToolbarHeight * 2);
                      final angle =
                          _calculateAngle(center, currentTouchPoint) + pi / 2;
                      handleRotate(angle);
                    },
                    onPanEnd: (details) {
                      onEditEnd.call();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: (controlSize + 10) / scale,
                        height: (controlSize + 10) / scale,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          // rounded border
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: strokeWidth / scale,
                          ),
                        ),
                        child: Icon(
                          Icons.rotate_left,
                          color: Colors.blueAccent,
                          size: 16 / scale,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Positioned _anchorBox({
    required double? top,
    required double? left,
    // callback on drag start
    required Null Function(DragStartDetails details) onDragStart,
    // callback on drag end
    required Null Function(DragEndDetails details) onDragEnd,
    required Null Function(DragUpdateDetails details) handleDrag,
    required MouseCursor cursor,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onPanStart: onDragStart,
        onPanEnd: onDragEnd,
        onPanUpdate: handleDrag,
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: controlSize / scale,
            height: controlSize / scale,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(
                color: Colors.blueAccent,
                width: strokeWidth / scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
