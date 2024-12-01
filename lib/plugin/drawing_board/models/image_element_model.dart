import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

class ImageElementModel extends GraphicElementModel {
  ImageElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    required this.url,
  }) : super(
          type: GraphicElementType.image,
        );

  String url;

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! ImageElementModel) return;
    url = newElement.url;

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? url,
  }) {
    this.url = url ?? this.url;

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
    if (newElement is! ImageElementModel) return;

    url = newElement.url;
  }

  // copyWith
  @override
  ImageElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? url,
    double? width,
    double? height,
  }) {
    return ImageElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'url': url,
      };

  @override
  String toString() {
    return 'ImageElementModel{url: $url}';
  }

  factory ImageElementModel.fromMap(Map<String, dynamic> data) {
    GraphicElementModel graphicElement = GraphicElementModel.fromMap(data);
    return ImageElementModel(
      bounds: graphicElement.bounds,
      decoration: graphicElement.decoration,
      opacity: graphicElement.opacity,
      visibility: graphicElement.visibility,
      rotation: graphicElement.rotation,
      url: data['url'],
    );
  }
}
