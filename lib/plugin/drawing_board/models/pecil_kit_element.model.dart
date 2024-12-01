import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

class PencilKitElementModel extends GraphicElementModel {
  PencilKitElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    this.data,
  }) : super(
          type: GraphicElementType.drawing,
        );

  String? data;

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! PencilKitElementModel) return;
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
    String? data = '',
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
    if (newElement is! PencilKitElementModel) return;
    data = newElement.data;
  }

  @override
  PencilKitElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation, // not used
    String? data,
  }) {
    return PencilKitElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      data: data ?? this.data,
    );
  }

  factory PencilKitElementModel.empty() {
    return PencilKitElementModel(
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
    return 'PencilKitElementModel{data: $data}';
  }

  factory PencilKitElementModel.fromMap(Map<String, dynamic> data) {
    GraphicElementModel graphicElementModel = PencilKitElementModel.empty();
    return PencilKitElementModel(
      bounds: graphicElementModel.bounds,
      decoration: graphicElementModel.decoration,
      opacity: graphicElementModel.opacity,
      visibility: graphicElementModel.visibility,
      data: data['data'],
    );
  }
}
