import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';

abstract class IGrahpicElementService {
  Future<void> appendGraphicElement({
    required String noteId,
    required String pageId,
    required GraphicElementModel element,
    String? ownerId,
  });
  Future<void> insertGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    required GraphicElementModel element,
    String? ownerId,
  });
  Future<void> updateGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    required GraphicElementModel element,
    String? ownerId,
  });
  Future<void> batchUpdateGraphicElements({
    required String noteId,
    required String pageId,
    required Map<int, GraphicElementModel> elements,
    String? ownerId,
  });
  Future<void> deleteGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    String? ownerId,
  });
}
