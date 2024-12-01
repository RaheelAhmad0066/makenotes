import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'tflite.dart';
import 'utils.dart';

final _canvasCullRect = Rect.fromPoints(
  const Offset(0, 0),
  Offset(Constants.imageSize, Constants.imageSize),
);

final _whitePaint = Paint()
  ..strokeCap = StrokeCap.round
  ..color = Colors.white
  ..strokeWidth = Constants.strokeWidth;

final _bgPaint = Paint()..color = Colors.black;

class Recognizer {
  bool _isModelLoaded = false;

  Future loadModel() async {
    debugPrint("Loading model...");
    if (_isModelLoaded) return;
    try {
      // await Tflite.close();
      String? res = await Tflite.loadModel(
        model: 'assets/mnist.tflite',
        labels: 'assets/mnist.txt',
      );
      if (res == null) {
        debugPrint('Error loading model: $res');
      } else {
        _isModelLoaded = true;
        debugPrint('Model loaded successfully: $res');
      }
    } catch (e) {
      debugPrint('Error loading model: $e');
      rethrow;
    }
  }

  dispose() async {
    debugPrint('Disposing recognizer...');
    _isModelLoaded = false;
    var res = await Tflite.close();
    debugPrint('Model closed: $res');
  }

  Future<Uint8List?> previewImage(List<Offset?> points) async {
    final picture = _pointsToPicture(points);
    final image = await picture.toImage(
        Constants.mnistImageSize, Constants.mnistImageSize);
    var pngBytes = await image.toByteData(format: ImageByteFormat.png);

    // Dispose the image and picture objects after conversion
    image.dispose();
    picture.dispose(); // Add this line

    // Release ByteData after extracting the Uint8List
    final uint8List = pngBytes?.buffer.asUint8List();
    pngBytes = null; // Explicitly set to null for garbage collection

    return uint8List;
  }

  Future recognize(List<Offset?> points) async {
    final picture = _pointsToPicture(points);
    Uint8List bytes =
        await _imageToByteListUint8(picture, Constants.mnistImageSize);

    // points.clear();
    // Dispose of the picture after processing to free up memory
    // picture.dispose();

    // Run the prediction
    try {
      var prediction = await _predict(bytes);

      // remove the bytes from memory
      bytes = Uint8List(0);

      return prediction;
    } catch (e) {
      debugPrint("Prediction error: $e");

      // remove the bytes from memory
      bytes = Uint8List(0);

      return null; // Return null in case of an error
    }
  }

  Future _predict(Uint8List bytes) {
    if (!_isModelLoaded) {
      bytes.clear();
      throw Exception('Model not loaded');
    }
    return Tflite.runModelOnBinary(binary: bytes);
  }

  Future<Uint8List> _imageToByteListUint8(Picture pic, int size) async {
    final img = await pic.toImage(size, size);
    final imgBytes = await img.toByteData();
    final resultBytes = Float32List(size * size);
    final buffer = Float32List.view(resultBytes.buffer);

    int index = 0;

    if (imgBytes == null) throw Exception('Could not read image');

    for (int i = 0; i < imgBytes.lengthInBytes; i += 4) {
      final r = imgBytes.getUint8(i);
      final g = imgBytes.getUint8(i + 1);
      final b = imgBytes.getUint8(i + 2);
      buffer[index++] = (r + g + b) / 3.0 / 255.0;
    }

    pic.dispose();
    img.dispose(); // Dispose the image after processing

    return resultBytes.buffer.asUint8List();
  }

  Picture _pointsToPicture(List<Offset?> points) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, _canvasCullRect)
      ..scale(Constants.mnistImageSize / Constants.canvasSize);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, Constants.imageSize, Constants.imageSize),
        _bgPaint);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, _whitePaint);
      }
    }

    // points.clear();

    return recorder.endRecording();
  }
}
