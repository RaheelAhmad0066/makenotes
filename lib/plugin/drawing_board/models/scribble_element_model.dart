import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import 'graphic_element_model.dart';

class ScribbleElementModel extends GraphicElementModel {
  late Sketch sketch;

  ScribbleElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    Sketch? sketch,
  }) : super(
          type: GraphicElementType.drawing,
        ) {
    this.sketch = sketch ?? const Sketch(lines: []);
  }

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! ScribbleElementModel) return;
    sketch = newElement.sketch;

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation, // not used
    Sketch? sketch,
  }) {
    this.sketch = sketch ?? this.sketch;

    super.updateWith(
      bounds: bounds,
      decoration: decoration,
      opacity: opacity,
      visibility: visibility,
    );
  }

  @override
  void update(GraphicElementModel newElement) {
    super.update(newElement);
    if (newElement is! ScribbleElementModel) return;
    // WIP: decide to add or replace sketches
    // sketches.addAll(newElement.sketches);
    sketch = newElement.sketch;
  }

  // copyWith
  @override
  ScribbleElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation, // not used
    Sketch? sketch,
  }) {
    return ScribbleElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      sketch: sketch ?? this.sketch.copyWith(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'sketch': sketch.toJson(),
      };

  factory ScribbleElementModel.fromMap(
    Map<String, dynamic> data,
  ) {
    GraphicElementModel graphicElementModel = ScribbleElementModel.empty();
    return ScribbleElementModel(
      bounds: graphicElementModel.bounds,
      decoration: graphicElementModel.decoration,
      opacity: graphicElementModel.opacity,
      visibility: graphicElementModel.visibility,
      sketch: Sketch.fromJson(data['sketch']),
    );
  }

  factory ScribbleElementModel.empty() {
    return ScribbleElementModel(
      bounds: const Rect.fromLTWH(0, 0, 0, 0),
      decoration: const BoxDecoration(color: Colors.transparent),
      opacity: 1.0,
      visibility: true,
      sketch: const Sketch(lines: []),
    );
  }
}
