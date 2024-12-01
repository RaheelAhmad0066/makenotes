import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';

import '../../../services/editor_page_service.dart';
import '../command.dart';

class UpdateDrawingBoardCommand extends Command {
  final EditorPageService pageService;
  final PageModel pageModel;

  final List<Map<String, dynamic>> newData;

  late List<Map<String, dynamic>> _newData;
  late List<Map<String, dynamic>> _oldData;

  UpdateDrawingBoardCommand({
    required this.pageService,
    required this.pageModel,
    required this.newData,
  }) {
    // _newSketch = newSketch.copyWith();
    // _oldSketch = pageModel.sketch.sketch.copyWith();
    _newData = List<Map<String, dynamic>>.from(newData);
    _oldData = List<Map<String, dynamic>>.from(
        pageModel.flutterDrawingBoardModel.data ?? []);
  }

  @override
  void execute() {
    pageModel.flutterDrawingBoardModel.updateWith(data: _newData);
    // pageModel.sketch.updateWith(sketch: _newData);
  }

  @override
  void undo() {
    pageModel.flutterDrawingBoardModel.updateWith(data: _oldData);
    // pageModel.sketch.updateWith(sketch: _oldData);
  }

  @override
  Future<void> queueExecute() async {
    try {
      await pageService.updatePageFlutterDrawingBoard(
        pageModel.id!,
        pageModel.flutterDrawingBoardModel.data ?? [],
      );
    } catch (e) {
      debugPrint('update drawing board error: $e');
      debugPrint('falling back to old drawing board');
      pageModel.flutterDrawingBoardModel.updateWith(data: _oldData);
      // pageModel.sketch.updateWith(sketch: _oldData);
      rethrow;
    }
  }

  @override
  Future<void> queueUndo() async {
    try {
      await pageService.updatePageFlutterDrawingBoard(
        pageModel.id!,
        pageModel.flutterDrawingBoardModel.data ?? [],
        // pageModel.sketch,
      );
    } catch (e) {
      debugPrint('update sketch error: $e');
      debugPrint('falling back to new sketch');
      pageModel.flutterDrawingBoardModel.updateWith(data: _newData);
      // pageModel.sketch.updateWith(sketch: _newData);
      rethrow;
    }
  }
}
