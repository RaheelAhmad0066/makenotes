import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

class VideoElementModel extends GraphicElementModel {
  VideoElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    required this.title,
    required this.content,
  }) : super(
          type: GraphicElementType.video,
        );

  String title;
  Uri content;

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! VideoElementModel) return;
    title = newElement.title;
    content = newElement.content;

    // newElement.bounds min width and height to 60
    if (newElement.bounds.width < 60 || newElement.bounds.height < 60) {
      newElement.bounds = Rect.fromCenter(
        center: newElement.bounds.center,
        width: newElement.bounds.width < 60 ? 60 : newElement.bounds.width,
        height: newElement.bounds.height < 60 ? 60 : newElement.bounds.height,
      );
    }

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? title,
    Uri? content,
    bool? published,
  }) {
    this.title = title ?? this.title;
    this.content = content ?? this.content;

    // bounds min width and height to 60
    if (bounds != null) {
      if (bounds.width < 60 || bounds.height < 60) {
        bounds = Rect.fromCenter(
          center: bounds.center,
          width: bounds.width < 60 ? 60 : bounds.width,
          height: bounds.height < 60 ? 60 : bounds.height,
        );
      }
    }

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
    if (newElement is! VideoElementModel) return;

    title = newElement.title;
    content = newElement.content;

    // newElement.bounds min width and height to 60
    if (newElement.bounds.width < 60 || newElement.bounds.height < 60) {
      newElement.bounds = Rect.fromCenter(
        center: newElement.bounds.center,
        width: newElement.bounds.width < 60 ? 60 : newElement.bounds.width,
        height: newElement.bounds.height < 60 ? 60 : newElement.bounds.height,
      );
    }
  }

  // copyWith
  @override
  VideoElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? title,
    Uri? content,
    bool? published,
  }) {
    return VideoElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'title': title,
        'content': content.toString(),
      };

  @override
  String toString() {
    return 'VideoElementModel{\n'
        '\t hash: ${super.hashCode}\n'
        '\t content: $content\n'
        '\t title: $title\n'
        '}\n';
  }

  factory VideoElementModel.fromMap(Map<String, dynamic> data) {
    GraphicElementModel graphicElement = GraphicElementModel.fromMap(data);
    return VideoElementModel(
      bounds: graphicElement.bounds,
      decoration: graphicElement.decoration,
      opacity: graphicElement.opacity,
      visibility: graphicElement.visibility,
      rotation: graphicElement.rotation,
      title: data['title'],
      content: Uri.parse(data['content']),
    );
  }

  bool compare(VideoElementModel other) {
    return title == other.title && content == other.content;
  }
}
