import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/models/flutter_drawing_board_model.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:provider/provider.dart';

class FlutterDrawingBoardElement extends StatefulWidget {
  const FlutterDrawingBoardElement({
    super.key,
    required this.drawingBoardElement,
    required this.controller,
    this.onUpdated,
    this.onDebouncedUpdate,
    this.enabled = false,
  });
  final FlutterDrawingBoardModel drawingBoardElement;
  final DrawingBoardController controller;

  final Function(List<Map<String, dynamic>>)? onUpdated;
  final Function(List<Map<String, dynamic>>)? onDebouncedUpdate;
  final bool enabled;

  static const int debounceTime = 1000; // ms

  @override
  State<FlutterDrawingBoardElement> createState() =>
      _FlutterDrawingBoardElementState();
}

class _FlutterDrawingBoardElementState
    extends State<FlutterDrawingBoardElement> {
  final DrawingController _drawingController = DrawingController();
  final TransformationController _transformationController =
      TransformationController();
  final Debouncer debouncer =
      Debouncer(milliseconds: FlutterDrawingBoardElement.debounceTime);

  @override
  void initState() {
    super.initState();

    final drawingControllersProvider = Provider.of<DrawingControllersProvider>(
      context,
      listen: false,
    );
    drawingControllersProvider.addController(
        hashCode.toString(), _drawingController);
    if (widget.enabled) {
      drawingControllersProvider.setActiveController(hashCode.toString());
    }

    _drawingController.addContents(widget.drawingBoardElement.data?.map((val) {
          switch (val['type']) {
            case 'SimpleLine':
              return SimpleLine.fromJson(val) as PaintContent;
            case 'Circle':
              return Circle.fromJson(val) as PaintContent;
            case 'Eraser':
              return Eraser.fromJson(val) as PaintContent;
            case 'Rectangle':
              return Rectangle.fromJson(val) as PaintContent;
            case 'SmoothLine':
              return SmoothLine.fromJson(val) as PaintContent;
            case 'StraightLine':
              return StraightLine.fromJson(val) as PaintContent;
            default:
              return SimpleLine.fromJson(val) as PaintContent;
          }
        }).toList() ??
        <PaintContent>[]);

    _drawingController.addListener(handleUpdate);
  }

  @override
  didUpdateWidget(FlutterDrawingBoardElement oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final drawingControllersProvider =
            Provider.of<DrawingControllersProvider>(
          context,
          listen: false,
        );
        if (widget.enabled) {
          drawingControllersProvider.setActiveController(hashCode.toString());
        } else {
          drawingControllersProvider.clearActiveController();
        }
      });
    }
  }

  void handleUpdate() {
    debugPrint('handleUpdate');
    final data = _drawingController.getJsonList();
    widget.onUpdated?.call(data);

    debouncer.run(() {
      widget.onDebouncedUpdate?.call(data);
    });
  }

  @override
  void dispose() {
    final drawingControllersProvider = Provider.of<DrawingControllersProvider>(
      context,
      listen: false,
    );
    drawingControllersProvider.removeController(hashCode.toString());

    _drawingController.removeListener(handleUpdate);
    _drawingController.clear();
    _drawingController.dispose();
    _transformationController.dispose();
    debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return DrawingBoard(
          transformationController: _transformationController,
          showDefaultActions: false,
          showDefaultTools: false,
          boardScaleEnabled: false,
          boardPanEnabled: false,
          controller: _drawingController,
          background: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: Colors.transparent,
          ),
        );
      },
    );
  }
}

class DrawingControllersProvider extends ChangeNotifier {
  DrawingControllersProvider();

  final Map<String, DrawingController> drawingControllers = {};

  DrawingController? activeController;

  void setActiveController(String key) {
    activeController = drawingControllers[key];
    notifyListeners();
  }

  void clearActiveController() {
    activeController = null;
    notifyListeners();
  }

  void addController(String key, DrawingController controller) {
    drawingControllers[key] = controller;
    notifyListeners();
  }

  void removeController(String key) {
    drawingControllers.remove(key);
    if (activeController == drawingControllers[key]) {
      activeController = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in drawingControllers.values) {
      controller.dispose();
    }
    drawingControllers.clear();
    super.dispose();
  }
}
