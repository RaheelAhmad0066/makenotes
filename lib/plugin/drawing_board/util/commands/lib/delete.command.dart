import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_page_service.dart';

import '../command.dart';

class DeleteCommand extends Command {
  final int elementIndex;
  final EditorPageService pageService;
  final PageModel pageModel;

  late GraphicElementModel _deletedElement;

  DeleteCommand({
    required this.elementIndex,
    required this.pageService,
    required this.pageModel,
  }) {
    _deletedElement = pageModel.graphicElements[elementIndex].copyWith();
  }

  @override
  void execute() {
    pageModel.deleteElement(elementIndex);
  }

  @override
  void undo() {
    pageModel.insertElement(elementIndex, _deletedElement);
  }

  @override
  Future<void> queueExecute() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint(
        'deleting element on server: $elementIndex, ${_deletedElement.hashCode}, $pageId');
    await pageService.deleteGraphicElement(
      pageId,
      elementIndex,
    );
  }

  @override
  Future<void> queueUndo() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint(
        'inserting element on server: $elementIndex, ${_deletedElement.hashCode}, $pageId');
    await pageService.insertGraphicElement(
      pageId,
      elementIndex,
      _deletedElement,
    );
  }

  @override
  String toString() {
    return 'DeleteCommand {\n'
        '  elementIndex: $elementIndex,\n'
        '  pageService: $pageService,\n'
        '  pageModel: ${pageModel.hashCode},\n'
        '  _deletedElement: ${_deletedElement.hashCode},\n'
        '}';
  }
}
