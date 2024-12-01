import 'dart:math';

import 'package:flutter/material.dart' hide TransformationController;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:pencil_kit/pencil_kit.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../util/drawing_mode.dart';
import '../util/widgets/custom_interactive_viewer.dart';

class DrawingBoardController extends ChangeNotifier {
  DrawingBoardController({
    required this.transformationController,
  });
  final TransformationController transformationController;

  PencilKitController? pencilKitController;
  DrawingController? drawingController;

  bool _isShowingPencilKit = false;
  bool _isHighlighting = false;
  DrawingMode _drawingMode = DrawingMode.pointer;
  double _penSize = 5;
  Color _penColor = Colors.black;
  TextStyle _textStyle = const TextStyle(color: Colors.black, fontSize: 20);
  double _currentScale = 1.0;
  double _exponent = 0.0;

  bool get isShowingPencilKit => _isShowingPencilKit;
  set isShowingPencilKit(bool value) {
    _isShowingPencilKit = value;
    notifyListeners();
  }

  bool get isHighlighting => _isHighlighting;
  set isHighlighting(bool value) {
    _isHighlighting = value;
    notifyListeners();
  }

  DrawingMode get drawingMode => _drawingMode;
  set drawingMode(DrawingMode value) {
    _drawingMode = value;
    notifyListeners();
  }

  double get penSize => _penSize;
  set penSize(double value) {
    _penSize = value;
    notifyListeners();
  }

  Color get penColor => _penColor;
  set penColor(Color value) {
    _penColor = value;
    notifyListeners();
  }

  TextStyle get textStyle => _textStyle;
  set textStyle(TextStyle value) {
    _textStyle = value;
    notifyListeners();
  }

  double get currentScale => _currentScale;
  set currentScale(double value) {
    _currentScale = value;
    notifyListeners();
  }

  double get exponent => _exponent;
  set exponent(double value) {
    _exponent = value;
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose of transformationController if it needs cleanup
    transformationController.dispose();
    // Nullify the PencilKitController if it has any listeners or resources to release
    // pencilKitController?.dispose();
    // Nullify the DrawingController if it has any listeners or resources to release
    drawingController?.dispose();
    super.dispose();
  }

  void zoomIn() {
    if (currentScale >= 8.0) return;
    exponent += 1;
    currentScale = pow(2, exponent / 4).toDouble().clamp(0.1, 8.0);

    var currentMatrix = transformationController.value.clone();
    var translation = currentMatrix.getTranslation();
    currentMatrix.setIdentity();
    currentMatrix.translate(translation);
    currentMatrix.scale(currentScale);

    transformationController.value = currentMatrix;
  }

  void zoomOut() {
    if (currentScale <= 0.1) return;
    exponent -= 1;
    currentScale = pow(2, exponent / 4).toDouble().clamp(0.1, 8.0);

    var currentMatrix = transformationController.value.clone();
    var translation = currentMatrix.getTranslation();
    currentMatrix.setIdentity();
    currentMatrix.translate(translation);
    currentMatrix.scale(currentScale);

    transformationController.value = currentMatrix;
  }

  void zoomReset({bool resetTranslation = false}) {
    var currentMatrix = transformationController.value.clone();
    if (resetTranslation) {
      currentMatrix.setIdentity();
    } else {
      var translation = currentMatrix.getTranslation();
      currentMatrix.setIdentity();
      currentMatrix.translate(translation);
    }
    transformationController.value = currentMatrix;

    currentScale = 1.0;
    exponent = 0.0;
  }

  double? _storedScale;
  Offset? _storedFocalPoint;
  Offset? _normalizedOffset;
  Offset _offset = Offset.zero;
  void zoomStart(Offset focalPoint) {
    final position = transformationController.value.getTranslation();
    _offset = Offset(position.x, position.y);
    _storedScale = currentScale;
    _storedFocalPoint = focalPoint;
    _normalizedOffset = (focalPoint - _offset) / currentScale;
  }

  void zoomUpdate(double scale, Offset latestfocalPoint) {
    if (_storedScale == null || _storedFocalPoint == null) return;

    currentScale = (_storedScale! * scale).clamp(0.1, 8.0);

    _offset = latestfocalPoint - _normalizedOffset! * currentScale;

    final currentMatrix = transformationController.value.clone();
    final adjustedTranslation = Vector3(_offset.dx, _offset.dy, 0.0);

    // Apply the transformation
    currentMatrix.setIdentity();
    currentMatrix.translate(adjustedTranslation.x, adjustedTranslation.y);
    currentMatrix.scale(currentScale);

    transformationController.value = currentMatrix;
  }

  void zoomEnd() {
    _storedScale = null;
    _storedFocalPoint = null;
    _normalizedOffset = null;
  }

  void zoom(double scaleFactor) {
    // increase or decrease current scale by scaleFactor
    currentScale *= scaleFactor;
    currentScale = currentScale.clamp(0.1, 8.0);

    var currentMatrix = transformationController.value.clone();
    var translation = currentMatrix.getTranslation();
    currentMatrix.setIdentity();
    currentMatrix.translate(translation);
    currentMatrix.scale(currentScale);

    transformationController.value = currentMatrix;
  }

  void move(Offset offset) {
    var currentMatrix = transformationController.value.clone();
    currentMatrix.translate(offset.dx, offset.dy);
    transformationController.value = currentMatrix;
  }
}
