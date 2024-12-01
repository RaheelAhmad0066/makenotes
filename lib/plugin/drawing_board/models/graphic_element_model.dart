import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/graphic_elements/explanation_element.dart';
import 'package:makernote/plugin/drawing_board/models/video_element_model.dart';

import '../graphic_elements/image_element.dart';
import '../graphic_elements/text_field_element.dart';
import '../graphic_elements/video_element.dart';
import 'explanation_element_model.dart';
import 'image_element_model.dart';
import 'scribble_element_model.dart';
import 'text_element_model.dart';

enum GraphicElementType {
  text,
  rectangle,
  drawing,
  image,
  video,
  explanation,
}

class GraphicElementModel extends ChangeNotifier {
  GraphicElementType type;
  Rect bounds;
  BoxDecoration decoration;
  double opacity;
  bool visibility;
  double rotation;

  GraphicElementModel({
    this.type = GraphicElementType.rectangle,
    required this.bounds,
    required this.decoration,
    required this.opacity,
    required this.visibility,
    this.rotation = 0,
  });

  // update with new element
  void updateWithElement(GraphicElementModel newElement) {
    bounds = newElement.bounds;
    decoration = newElement.decoration;
    opacity = newElement.opacity;
    visibility = newElement.visibility;
    rotation = newElement.rotation;

    notifyListeners();
  }

  // update with specific values
  void updateWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
  }) {
    this.bounds = bounds ?? this.bounds;
    this.decoration = decoration ?? this.decoration;
    this.opacity = opacity ?? this.opacity;
    this.visibility = visibility ?? this.visibility;
    this.rotation = rotation ?? this.rotation;

    notifyListeners();
  }

  /// Update the element with new values
  void update(GraphicElementModel newElement) {
    type = newElement.type;
    bounds = newElement.bounds;
    decoration = newElement.decoration;
    opacity = newElement.opacity;
    visibility = newElement.visibility;
    rotation = newElement.rotation;
  }

  // copyWith
  GraphicElementModel copyWith({
    Rect? bounds,
    BoxDecoration? decoration,
    double? opacity,
    bool? visibility,
    double? rotation,
  }) {
    return GraphicElementModel(
      type: type,
      bounds: bounds ?? this.bounds,
      decoration: decoration ?? this.decoration,
      opacity: opacity ?? this.opacity,
      visibility: visibility ?? this.visibility,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.index,
        'bounds': {
          'left': bounds.left,
          'top': bounds.top,
          'width': bounds.width,
          'height': bounds.height,
        },
        'decoration': {
          'color': decoration.color?.value,
          'borderRadius':
              (decoration.borderRadius as BorderRadius?)?.bottomLeft.x ?? 0,
        },
        'opacity': opacity,
        'visibility': visibility,
        'rotation': rotation,
      };

  factory GraphicElementModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return GraphicElementModel(
      type: GraphicElementType.values[data['type']],
      bounds: Rect.fromLTWH(
        (data['bounds']['left'] as num).toDouble(),
        (data['bounds']['top'] as num).toDouble(),
        (data['bounds']['width'] as num).toDouble(),
        (data['bounds']['height'] as num).toDouble(),
      ),
      decoration: BoxDecoration(
        color: Color(data['decoration']['color']),
        borderRadius: BorderRadius.circular(
          (data['decoration']['borderRadius'] as num).toDouble(),
        ),
      ),
      opacity: (data['opacity'] as num).toDouble(),
      visibility: data['visibility'],
      rotation: (data['rotation'] as num? ?? 0).toDouble(),
    );
  }

  factory GraphicElementModel.fromType(
      GraphicElementType type, Map<String, dynamic> data) {
    switch (type) {
      case GraphicElementType.text:
        return TextElementModel.fromMap(data);
      case GraphicElementType.rectangle:
        return GraphicElementModel.fromMap(data);
      case GraphicElementType.drawing:
        return ScribbleElementModel.fromMap(data);
      case GraphicElementType.image:
        return ImageElementModel.fromMap(data);
      case GraphicElementType.video:
        return VideoElementModel.fromMap(data);
      case GraphicElementType.explanation:
        return ExplanationElementModel.fromMap(data);
      default:
        return GraphicElementModel.fromMap(data);
    }
  }

  static Widget getElementWidget({
    required GraphicElementModel element,
    // callback for different elements content changes
  }) {
    return switch (element.type) {
      GraphicElementType.text => TextFieldElement(
          key: ValueKey(element.hashCode),
          textElement: element as TextElementModel,
        ),
      GraphicElementType.rectangle => Container(),
      GraphicElementType.image => ImageElement(
          key: ValueKey(element.hashCode),
          imageElement: element as ImageElementModel,
        ),
      GraphicElementType.video => VideoElement(
          key: ValueKey(element.hashCode),
          videoElement: element as VideoElementModel,
        ),
      GraphicElementType.explanation => ExplanationElement(
          explanationElement: element as ExplanationElementModel,
        ),
      GraphicElementType.drawing =>
        // throw error because drawing element should not be rendered
        throw 'Drawing element should not be rendered',
    };
  }
}
