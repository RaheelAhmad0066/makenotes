import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'drawing_painter.dart';
import 'predition.dart';
import 'predition_widget.dart';
import 'recognizer.dart';
import 'utils.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final List<Offset?> _points = [];
  final _recognizer = Recognizer();
  List<Prediction> _prediction = [];
  bool initialize = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState called');
    _initModel();
  }

  @override
  void dispose() {
    _points.clear();
    _prediction.clear();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digit Recognizer'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'MNIST database of handwritten digits',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'The digits have been size-normalized and centered in a fixed-size images (28 x 28)',
                      )
                    ],
                  ),
                ),
              ),
              _mnistPreviewImage(),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          _drawCanvasWidget(),
          const SizedBox(
            height: 10,
          ),
          PredictionWidget(
            predictions: _prediction,
            key: UniqueKey(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.clear),
        onPressed: () {
          setState(() {
            _points.clear();
            _prediction.clear();
          });
        },
      ),
    );
  }

  Widget _drawCanvasWidget() {
    return Container(
      width: Constants.canvasSize + Constants.borderSize * 2,
      height: Constants.canvasSize + Constants.borderSize * 2,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.amber,
          width: Constants.borderSize,
        ),
      ),
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          Offset localPosition = details.localPosition;
          if (localPosition.dx >= 0 &&
              localPosition.dx <= Constants.canvasSize &&
              localPosition.dy >= 0 &&
              localPosition.dy <= Constants.canvasSize) {
            setState(() {
              _points.add(localPosition);
            });
          }
        },
        onPanEnd: (DragEndDetails details) {
          _points.add(null);
          _recognize();
        },
        child: CustomPaint(
          painter: DrawingPainter(_points),
        ),
      ),
    );
  }

  Widget _mnistPreviewImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.black,
      child: FutureBuilder(
        future: _previewImage(),
        builder: (BuildContext _, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.fill,
            );
          } else {
            return const Center(
              child: Text('Error'),
            );
          }
        },
      ),
    );
  }

  void _initModel() async {
    await _recognizer.loadModel();

    debugPrint('[Drawing Widget] Model loaded');
  }

  Future<Uint8List?> _previewImage() async {
    return await _recognizer.previewImage(_points);
  }

  void _recognize() async {
    List<dynamic> pred = await _recognizer.recognize(_points);

    for (var element in pred) {
      debugPrint("Element: $element");
    }

    setState(() {
      _prediction = pred.map((json) => Prediction.fromJson(json)).toList();
    });
  }
}
