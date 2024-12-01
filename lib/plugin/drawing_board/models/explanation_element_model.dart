import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

class ExplanationElementModel extends GraphicElementModel {
  ExplanationElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    required this.title,
    required this.content,
    this.published = false,
  }) : super(
          type: GraphicElementType.explanation,
        );

  String title;
  Uri content;
  bool published;

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! ExplanationElementModel) return;
    title = newElement.title;
    content = newElement.content;
    published = newElement.published;

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
    this.published = published ?? this.published;

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
    if (newElement is! ExplanationElementModel) return;

    title = newElement.title;
    content = newElement.content;
    published = newElement.published;
  }

  // copyWith
  @override
  ExplanationElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? title,
    Uri? content,
    bool? published,
  }) {
    return ExplanationElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
      title: title ?? this.title,
      content: content ?? this.content,
      published: published ?? this.published,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'title': title,
        'content': content.toString(),
        'published': published,
      };

  @override
  String toString() {
    return 'ExplanationElementModel{\n'
        '\t hash: ${super.hashCode}\n'
        '\t content: $content\n'
        '\t title: $title\n'
        '\t published: $published\n'
        '}\n';
  }

  factory ExplanationElementModel.fromMap(Map<String, dynamic> data) {
    GraphicElementModel graphicElement = GraphicElementModel.fromMap(data);
    return ExplanationElementModel(
      bounds: graphicElement.bounds,
      decoration: graphicElement.decoration,
      opacity: graphicElement.opacity,
      visibility: graphicElement.visibility,
      rotation: graphicElement.rotation,
      title: data['title'],
      content: Uri.parse(data['content']),
      published: data['published'] ?? false,
    );
  }

  bool compare(ExplanationElementModel other) {
    return title == other.title &&
        content == other.content &&
        published == other.published;
  }
}
