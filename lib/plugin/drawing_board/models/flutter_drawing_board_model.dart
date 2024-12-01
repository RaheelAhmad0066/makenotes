import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

class FlutterDrawingBoardModel extends GraphicElementModel {
  FlutterDrawingBoardModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    this.data,
  }) : super(
          type: GraphicElementType.drawing,
        );

  List<Map<String, dynamic>>? data;

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! FlutterDrawingBoardModel) return;
    data = newElement.data;

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation, // not used
    List<Map<String, dynamic>>? data = const [],
  }) {
    this.data = data?.isEmpty == true ? this.data : data;

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
    if (newElement is! FlutterDrawingBoardModel) return;
    data = newElement.data;
  }

  @override
  FlutterDrawingBoardModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation, // not used
    List<Map<String, dynamic>>? data,
  }) {
    return FlutterDrawingBoardModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      data: data ?? this.data,
    );
  }

  factory FlutterDrawingBoardModel.empty() {
    return FlutterDrawingBoardModel(
      bounds: const Rect.fromLTWH(0, 0, 0, 0),
      decoration: const BoxDecoration(color: Colors.transparent),
      opacity: 1.0,
      visibility: true,
      data: null,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'data': data,
      };

  @override
  String toString() {
    return 'FlutterDrawingBoardModel{data: $data}';
  }

  factory FlutterDrawingBoardModel.fromMap(Map<String, dynamic> data) {
    GraphicElementModel graphicElementModel = FlutterDrawingBoardModel.empty();
    return FlutterDrawingBoardModel(
      bounds: graphicElementModel.bounds,
      decoration: graphicElementModel.decoration,
      opacity: graphicElementModel.opacity,
      visibility: graphicElementModel.visibility,
      data: (data['data'] as List<dynamic>?)
              ?.whereType<
                  Map<String,
                      dynamic>>() // Ensure each item is of the correct type
              .map((item) => item)
              .toList() ??
          [],
    );
  }
}
