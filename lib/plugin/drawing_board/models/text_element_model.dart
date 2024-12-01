import 'package:flutter/material.dart';

import 'graphic_element_model.dart';

import '../extension/text_decoration.extension.dart';

class TextElementModel extends GraphicElementModel {
  EdgeInsetsGeometry padding = const EdgeInsets.all(10.0);
  String text;
  TextStyle textStyle;
  TextDirection textDirection;

  TextElementModel({
    required super.bounds,
    required super.decoration,
    required super.opacity,
    required super.visibility,
    super.rotation,
    required this.text,
    required this.textStyle,
    this.textDirection = TextDirection.ltr,
  }) : super(
          type: GraphicElementType.text,
        ) {
    textStyle = textStyle.copyWith(
      fontSize: textStyle.fontSize ?? 20,
      color: textStyle.color ?? Colors.black,
      height: textStyle.height ?? 1.5,
    );
    super.bounds = getNewBounds();
  }

  Rect getNewBounds() {
    Size textSize = getTextSize(padding);
    return Rect.fromLTWH(
      bounds.left,
      bounds.top,
      bounds.width < textSize.width ? textSize.width : bounds.width,
      bounds.height < textSize.height ? textSize.height : bounds.height,
    );
  }

  Size getTextSize(EdgeInsetsGeometry padding) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle,
      ),
      maxLines: null,
      textDirection: textDirection,
    )..layout(
        minWidth: 0,
        maxWidth: double.infinity,
      );
    var s = Size(
      textPainter.size.width + padding.horizontal + textStyle.fontSize!,
      textPainter.size.height + padding.vertical + textStyle.fontSize!,
    );
    textPainter.dispose();
    return s;
  }

  @override
  String toString() {
    return 'TextElementModel{\n bounds: $bounds,\n  decoration: $decoration,\n  opacity: $opacity,\n  visibility: $visibility,\n  text: $text,\n  textStyle: $textStyle,\n  textDirection: $textDirection\n}';
  }

  @override
  void updateWithElement(GraphicElementModel newElement) {
    if (newElement is! TextElementModel) return;
    super.bounds = getNewBounds();
    text = newElement.text;
    textStyle = newElement.textStyle;
    textDirection = newElement.textDirection;

    super.updateWithElement(newElement);
  }

  @override
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? text,
    TextStyle? textStyle,
    TextDirection? textDirection,
  }) {
    super.bounds = getNewBounds();
    this.text = text ?? this.text;
    this.textStyle = textStyle ?? this.textStyle;
    this.textDirection = textDirection ?? this.textDirection;

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
    if (newElement is! TextElementModel) return;
    super.bounds = getNewBounds();
    text = newElement.text;
    textStyle = newElement.textStyle;
    textDirection = newElement.textDirection;
  }

  // copyWith
  @override
  TextElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
    String? text,
    TextStyle? textStyle,
    TextDirection? textDirection,
  }) {
    return TextElementModel(
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      textDirection: textDirection ?? this.textDirection,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'text': text,
        'textStyle': {
          'color': textStyle.color!.value,
          'fontSize': textStyle.fontSize,
          'fontWeight': textStyle.fontWeight?.index,
          'fontStyle': textStyle.fontStyle?.index,
          'height': textStyle.height,
          'decoration': textStyle.decoration?.toCustomString(),
        },
        'textDirection': textDirection.index,
      };

  factory TextElementModel.fromMap(
    Map<String, dynamic> data,
  ) {
    GraphicElementModel graphicElementModel = GraphicElementModel.fromMap(data);
    return TextElementModel(
      bounds: graphicElementModel.bounds,
      decoration: graphicElementModel.decoration,
      opacity: graphicElementModel.opacity,
      visibility: graphicElementModel.visibility,
      rotation: graphicElementModel.rotation,
      text: data['text'],
      textStyle: TextStyle(
        color: Color(data['textStyle']['color']),
        fontSize: (data['textStyle']['fontSize'] as num?)?.toDouble(),
        fontWeight: data['textStyle']['fontWeight'] != null
            ? FontWeight.values[data['textStyle']['fontWeight']]
            : null,
        fontStyle: data['textStyle']['fontStyle'] != null
            ? FontStyle.values[data['textStyle']['fontStyle']]
            : null,
        height: (data['textStyle']['height'] as num?)?.toDouble(),
        decoration: TextDecorationExtension.fromCustomString(
            data['textStyle']['decoration']),
      ),
      textDirection: TextDirection.values[data['textDirection']],
    );
  }
}
