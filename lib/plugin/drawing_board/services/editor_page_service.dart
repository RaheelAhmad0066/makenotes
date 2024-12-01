import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:makernote/models/note_model.dart';

import './i_graphic_element_service.interface.dart';
import './i_page_service.interface.dart';
import '../models/graphic_element_model.dart';
import '../models/page_model.dart';
import '../models/scribble_element_model.dart';
import '../util/cache_updater.dart';

class EditorPageService extends ChangeNotifier {
  EditorPageService({
    required this.pageService,
    required this.grahpicElementService,
    required this.note,
    required this.currentPage,
  }) {
    init();
  }

  final IPageService pageService;
  final IGrahpicElementService grahpicElementService;
  final NoteModel note;
  final PageModel currentPage;

  // cached graphic elements
  late CacheUpdater<Map<int, GraphicElementModel>> _cachedElements;

  // max update frequency
  final double _maxUpdateFrequency = 0.33; // in seconds

  void init() {
    _cachedElements = CacheUpdater<Map<int, GraphicElementModel>>(
      batchUpdate: (elements) async {
        if (elements.isEmpty) return;
        // merge all elements into one map
        final mergedElements = <int, GraphicElementModel>{};
        for (var element in elements) {
          mergedElements.addAll(element);
        }

        await grahpicElementService.batchUpdateGraphicElements(
          noteId: note.id!,
          pageId: currentPage.id!,
          elements: mergedElements,
          ownerId: note.ownerId,
        );
      },
      maxUpdateFrequency: _maxUpdateFrequency,
    );
  }

  // dispose
  @override
  void dispose() {
    _cachedElements.dispose();
    super.dispose();
  }

  // append graphic element to page
  Future<void> appendGraphicElement(
      String pageId, GraphicElementModel element) async {
    await grahpicElementService.appendGraphicElement(
      noteId: note.id!,
      ownerId: note.ownerId,
      pageId: pageId,
      element: element,
    );
  }

  // insert graphic element to page
  Future<void> insertGraphicElement(
    String pageId,
    int index,
    GraphicElementModel element,
  ) async {
    await grahpicElementService.insertGraphicElement(
      noteId: note.id!,
      ownerId: note.ownerId,
      pageId: pageId,
      index: index,
      element: element,
    );
  }

  // update graphic element
  Future<void> updateGraphicElement(
    String pageId,
    int index,
    GraphicElementModel element,
  ) async {
    await _cachedElements.push({index: element});
  }

  // delete graphic element
  Future<void> deleteGraphicElement(
    String pageId,
    int index,
  ) async {
    await grahpicElementService.deleteGraphicElement(
      noteId: note.id!,
      pageId: pageId,
      index: index,
      ownerId: note.ownerId,
    );
  }

  // update page sketch
  Future<void> updatePageSketch(
      String pageId, ScribbleElementModel sketch) async {
    await pageService.updatePageSketch(
      noteId: note.id!,
      pageId: currentPage.id!,
      sketch: sketch,
      ownerId: note.ownerId,
    );
  }

  // update page pencil kit
  Future<void> updatePagePencilKit(String pageId, String? pencilKitData) async {
    await pageService.updatePagePencilKit(
      noteId: note.id!,
      pageId: currentPage.id!,
      data: pencilKitData,
      ownerId: note.ownerId,
    );
  }

  // update page flutter drawing board
  Future<void> updatePageFlutterDrawingBoard(
    String pageId,
    List<Map<String, dynamic>> data,
  ) async {
    await pageService.updatePageFlutterDrawingBoard(
      noteId: note.id!,
      pageId: currentPage.id!,
      data: data,
      ownerId: note.ownerId,
    );
  }
}
