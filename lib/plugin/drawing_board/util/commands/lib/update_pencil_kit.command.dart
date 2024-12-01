import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';

import '../../../services/editor_page_service.dart';
import '../command.dart';

class UpdatePencilKitCommand extends Command {
  final EditorPageService pageService;
  final PageModel pageModel;
  final String? newData;

  late String? _newData;
  late String? _oldData;

  UpdatePencilKitCommand({
    required this.pageService,
    required this.pageModel,
    required this.newData,
  }) {
    _newData = newData;
    _oldData = pageModel.pencilKit.data;
  }

  @override
  void execute() {
    pageModel.pencilKit.updateWith(data: _newData);
  }

  @override
  void undo() {
    pageModel.pencilKit.updateWith(data: _oldData);
  }

  @override
  Future<void> queueExecute() async {
    try {
      debugPrint("[${pageModel.id}] update command");
      await pageService.updatePagePencilKit(
        pageModel.id!,
        _newData,
      );
    } catch (e) {
      debugPrint('update pencil kit error: $e');
      debugPrint('falling back to old data');
      // pageModel.pencilKit.updateWith(data: _oldData);
      rethrow;
    }
  }

  @override
  Future<void> queueUndo() async {
    try {
      await pageService.updatePagePencilKit(
        pageModel.id!,
        _oldData,
      );
    } catch (e) {
      debugPrint('update pencil kit error: $e');
      debugPrint('falling back to new data');
      // pageModel.pencilKit.updateWith(data: _newData);
      rethrow;
    }
  }
}
