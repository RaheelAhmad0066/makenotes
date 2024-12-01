import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/models/scribble_element_model.dart';

abstract class IPageService {
  Future<List<PageModel>> getPages(String noteId, String? ownerId);
  Stream<List<PageModel>> getPagesStream(String noteId, String? ownerId);
  Future<PageModel> appendPage({
    required String noteId,
    PageModel? page,
    String? ownerId,
  });
  Future<PageModel> insertPage({
    required String noteId,
    required int position,
    PageModel? page,
    String? ownerId,
  });
  Future<void> updatePage({
    required String noteId,
    required PageModel page,
    String? ownerId,
  });
  Future<void> deletePage({
    required String noteId,
    required String pageId,
    String? ownerId,
  });
  Future<void> updatePageSketch({
    required String noteId,
    required String pageId,
    required ScribbleElementModel sketch,
    String? ownerId,
  });
  Future<void> updatePagePencilKit({
    required String noteId,
    required String pageId,
    required String? data,
    String? ownerId,
  });
  Future<void> updatePageFlutterDrawingBoard({
    required String noteId,
    required String pageId,
    required List<Map<String, dynamic>> data,
    String? ownerId,
  });
  Future<void> clearPageSketch({
    required String noteId,
    required String pageId,
    String? ownerId,
  });
}
