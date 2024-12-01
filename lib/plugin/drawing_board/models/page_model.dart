import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'flutter_drawing_board_model.dart';
import 'graphic_element_model.dart';
import 'pecil_kit_element.model.dart';
import 'scribble_element_model.dart';

class PageModel extends ChangeNotifier {
  static const Size a4 = Size(2480 / 2, 3508 / 2);

  final String? id;
  String? referenceId;
  int order;
  Size size;
  late final List<GraphicElementModel> graphicElements;
  late ScribbleElementModel sketch;
  late PencilKitElementModel pencilKit;
  late FlutterDrawingBoardModel flutterDrawingBoardModel;
  String? backgroundImageUrl;

  PageModel({
    this.id,
    this.referenceId,
    this.order = 0,
    // set init size to A4
    this.size = a4,
    List<GraphicElementModel>? graphicElements,
    ScribbleElementModel? sketch,
    PencilKitElementModel? pencilKit,
    FlutterDrawingBoardModel? flutterDrawingBoard,
    this.backgroundImageUrl,
  }) {
    this.sketch = sketch ?? ScribbleElementModel.empty();
    this.pencilKit = pencilKit ?? PencilKitElementModel.empty();
    this.flutterDrawingBoardModel =
        flutterDrawingBoard ?? FlutterDrawingBoardModel.empty();
    this.graphicElements =
        graphicElements ?? <GraphicElementModel>[].toList(growable: true);
  }

  void updateElement(int index, GraphicElementModel newElement) {
    graphicElements[index] = newElement;
    notifyListeners();
  }

  void appendElement(GraphicElementModel newElement) {
    graphicElements.add(newElement);
    notifyListeners();
  }

  void insertElement(int index, GraphicElementModel newElement) {
    graphicElements.insert(index, newElement);
    notifyListeners();
  }

  void deleteElement(int index) {
    graphicElements.removeAt(index);
    notifyListeners();
  }

  void update(PageModel pageModel) {
    referenceId = pageModel.referenceId;
    order = pageModel.order;
    size = pageModel.size;
    var temp = graphicElements.toList();
    graphicElements.clear();
    graphicElements.addAll(temp);
    sketch.update(pageModel.sketch);
    pencilKit.update(pageModel.pencilKit);
    flutterDrawingBoardModel.update(pageModel.flutterDrawingBoardModel);
    backgroundImageUrl = pageModel.backgroundImageUrl;
    notifyListeners();
  }

  void updateWith({
    String? referenceId,
    int? order,
    Size? size,
    List<GraphicElementModel>? graphicElements,
    ScribbleElementModel? sketch,
    PencilKitElementModel? pencilKit,
    FlutterDrawingBoardModel? flutterDrawingBoard,
    String? backgroundImageUrl,
  }) {
    this.referenceId = referenceId ?? this.referenceId;
    this.order = order ?? this.order;
    this.size = size ?? this.size;
    var temp = graphicElements ?? this.graphicElements.toList();
    this.graphicElements.clear();
    this.graphicElements.addAll(temp);
    this.sketch.update(sketch ?? this.sketch);
    this.pencilKit.update(pencilKit ?? this.pencilKit);
    this
        .flutterDrawingBoardModel
        .update(flutterDrawingBoard ?? this.flutterDrawingBoardModel);
    this.backgroundImageUrl =
        (backgroundImageUrl != null && backgroundImageUrl.isEmpty)
            ? null
            : backgroundImageUrl ?? this.backgroundImageUrl;
    notifyListeners();
  }

  PageModel copyWith({
    String? referenceId,
    int? order,
    Size? size,
    List<GraphicElementModel>? graphicElements,
    ScribbleElementModel? sketch,
    PencilKitElementModel? pencilKit,
    FlutterDrawingBoardModel? flutterDrawingBoard,
    String? backgroundImageUrl,
  }) {
    return PageModel(
      id: id,
      referenceId: referenceId ?? this.referenceId,
      order: order ?? this.order,
      size: size ?? this.size,
      graphicElements: graphicElements ?? this.graphicElements,
      sketch: sketch ?? this.sketch,
      pencilKit: pencilKit ?? this.pencilKit,
      flutterDrawingBoard: flutterDrawingBoard ?? this.flutterDrawingBoardModel,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (referenceId != null) 'referenceId': referenceId,
        'order': order,
        'size': {'width': size.width, 'height': size.height},
        'graphicElements':
            graphicElements.map((element) => element.toMap()).toList(),
        'sketch': sketch.toMap(),
        'pencilKit': pencilKit.toMap(),
        'flutterDrawingBoard': flutterDrawingBoardModel.toMap(),
        'backgroundImageUrl': backgroundImageUrl,
      };

  factory PageModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PageModel(
      id: doc.id,
      referenceId: data['referenceId'] as String?,
      order: (data['order'] as num).toInt(),
      size: Size(
        ((data['size'] as Map<String, dynamic>?)?['width'] as num?)
                ?.toDouble() ??
            a4.width,
        ((data['size'] as Map<String, dynamic>?)?['height'] as num?)
                ?.toDouble() ??
            a4.height,
      ),
      graphicElements: (data['graphicElements'] as List<dynamic>)
          .map(
            (element) => GraphicElementModel.fromType(
                GraphicElementType.values[element['type']], element),
          )
          .toList(),
      sketch: ScribbleElementModel.fromMap(
          Map<String, dynamic>.from(data['sketch'])),
      pencilKit: data['pencilKit'] == null
          ? PencilKitElementModel.empty()
          : PencilKitElementModel.fromMap(
              Map<String, dynamic>.from(data['pencilKit'])),
      flutterDrawingBoard: data['flutterDrawingBoard'] == null
          ? FlutterDrawingBoardModel.empty()
          : FlutterDrawingBoardModel.fromMap(
              Map<String, dynamic>.from(data['flutterDrawingBoard'])),
      backgroundImageUrl: data['backgroundImageUrl'] as String?,
    );
  }

  factory PageModel.empty() {
    return PageModel(
      order: 0,
      graphicElements: [],
      sketch: ScribbleElementModel.empty(),
      pencilKit: PencilKitElementModel.empty(),
    );
  }

  @override
  String toString() {
    return '\n\tPageModel: \n'
        '\t\t id: $id \n'
        '\t\t referenceId: $referenceId \n'
        '\t\t order: $order \n'
        '\t\t size: $size \n'
        '\t\t graphicElements: $graphicElements \n'
        '\t\t sketch: $sketch \n'
        '\t\t pencilKit: $pencilKit \n'
        '\t\t flutterDrawingBoard: $flutterDrawingBoardModel \n'
        '\t\t backgroundImageUrl: $backgroundImageUrl \n';
  }
}
