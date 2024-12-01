import 'package:flutter/material.dart';

import '../util/sketch.dart';
import 'graphic_element_model.dart';

class DrawingElementModel extends GraphicElementModel {
  late List<Sketch> sketches;

  DrawingElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    sketches,
  }) : super(
          type: GraphicElementType.drawing,
        ) {
    this.sketches = sketches ?? List<Sketch>.empty(growable: true);
  }

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! DrawingElementModel) return;
    sketches = newElement.sketches;

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    List<Sketch>? sketches,
  }) {
    this.sketches = sketches ?? this.sketches;

    super.updateWith(
      bounds: bounds,
      decoration: decoration,
      opacity: opacity,
      visibility: visibility,
      rotation: rotation,
    );
  }

  @override
  void update(GraphicElementModel newElement) {
    super.update(newElement);
    if (newElement is! DrawingElementModel) return;
    // WIP: decide to add or replace sketches
    // sketches.addAll(newElement.sketches);
    sketches = newElement.sketches;
  }

  // copyWith
  @override
  DrawingElementModel copyWith({
    GraphicElementType? type,
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    List<Sketch>? sketches,
  }) {
    return DrawingElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
      sketches: sketches ?? this.sketches,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'sketches': sketches
            .map((e) => {
                  'points': e.points
                      .map((e) => {
                            'x': e!.dx,
                            'y': e.dy,
                          })
                      .toList(),
                  'color': e.color.value,
                  'strokeWidth': e.size,
                })
            .toList(),
      };

  factory DrawingElementModel.fromMap(
    Map<String, dynamic> data,
  ) {
    GraphicElementModel graphicElementModel = GraphicElementModel.fromMap(data);
    return DrawingElementModel(
      bounds: graphicElementModel.bounds,
      decoration: graphicElementModel.decoration,
      opacity: graphicElementModel.opacity,
      visibility: graphicElementModel.visibility,
      rotation: graphicElementModel.rotation,
      sketches: (data['sketches'] as List)
          .map((e) => Sketch(
                points: (e['points'] as List)
                    .map((e) => Offset(
                        (e['x'] as num).toDouble(), (e['y'] as num).toDouble()))
                    .toList(),
                color: Color(e['color']),
                size: (e['strokeWidth'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}
