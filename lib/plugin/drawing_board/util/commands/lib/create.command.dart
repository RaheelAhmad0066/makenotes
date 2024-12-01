import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_page_service.dart';

import '../command.dart';

class CreateCommand extends Command {
  late GraphicElementModel newElement;
  final EditorPageService pageService;
  final PageModel pageModel;

  late final int _index;

  CreateCommand({
    required GraphicElementModel newElement,
    required this.pageService,
    required this.pageModel,
  }) {
    this.newElement = newElement.copyWith();

    debugPrint('new element: ${newElement.bounds}');

    _index = pageModel.graphicElements.length;
  }

  @override
  void execute() {
    pageModel.appendElement(newElement);
  }

  @override
  void undo() {
    pageModel.deleteElement(_index);
  }

  @override
  Future<void> queueExecute() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint(
        'appending element on server: ${pageModel.graphicElements.length - 1}, ${newElement.hashCode}, $pageId');
    await pageService.appendGraphicElement(
      pageId,
      newElement,
    );
  }

  @override
  Future<void> queueUndo() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint(
        'deleting element on server: $_index, ${newElement.hashCode}, $pageId');
    await pageService.deleteGraphicElement(
      pageId,
      _index,
    );
  }

  @override
  String toString() {
    return 'CreateCommand {\n'
        '  newElement: $newElement,\n'
        '  pageService: $pageService,\n'
        '  pageModel: ${pageModel.hashCode},\n'
        '  _index: $_index,\n'
        '}';
  }
}
