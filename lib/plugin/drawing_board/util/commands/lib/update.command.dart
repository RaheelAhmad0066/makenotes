import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_page_service.dart';

import '../command.dart';

class UpdateCommand extends Command {
  late GraphicElementModel newElement;
  final int elementIndex;
  final EditorPageService pageService;
  final PageModel pageModel;

  late GraphicElementModel _oldElement;

  UpdateCommand({
    required GraphicElementModel newElement,
    required this.elementIndex,
    required this.pageService,
    required this.pageModel,
  }) {
    this.newElement = newElement.copyWith();
    _oldElement = pageModel.graphicElements[elementIndex].copyWith();
  }

  @override
  void execute() {
    var element = pageModel.graphicElements[elementIndex];
    element.updateWithElement(newElement);
  }

  @override
  void undo() {
    var element = pageModel.graphicElements[elementIndex];
    element.updateWithElement(_oldElement);
  }

  @override
  Future<void> queueExecute() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint('execute update element on server: $elementIndex, $pageId');
    await pageService.updateGraphicElement(
      pageId,
      elementIndex,
      newElement,
    );
  }

  @override
  Future<void> queueUndo() async {
    // update the element on the server
    final pageId = pageModel.id;

    if (pageId == null) return;
    debugPrint('undo update element on server: $elementIndex, $pageId');
    await pageService.updateGraphicElement(
      pageId,
      elementIndex,
      _oldElement,
    );
  }

  @override
  String toString() {
    return 'UpdateCommand: {\n'
        '  newElement: ${newElement.hashCode},\n'
        '  elementIndex: $elementIndex,\n'
        '  pageService: ${pageService.hashCode},\n'
        '  pageModel: ${pageModel.hashCode},\n'
        '  _oldElement: ${_oldElement.hashCode},\n'
        '}';
  }
}
