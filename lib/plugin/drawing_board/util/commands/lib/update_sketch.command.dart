import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:scribble/scribble.dart';

import '../../../services/editor_page_service.dart';
import '../command.dart';

class UpdateSketchCommand extends Command {
  final EditorPageService pageService;
  final PageModel pageModel;
  final Sketch newSketch;

  late Sketch _newSketch;
  late Sketch _oldSketch;

  UpdateSketchCommand({
    required this.pageService,
    required this.pageModel,
    required this.newSketch,
  }) {
    _newSketch = newSketch.copyWith();
    _oldSketch = pageModel.sketch.sketch.copyWith();
  }

  @override
  void execute() {
    pageModel.sketch.updateWith(sketch: _newSketch);
  }

  @override
  void undo() {
    pageModel.sketch.updateWith(sketch: _oldSketch);
  }

  @override
  Future<void> queueExecute() async {
    try {
      await pageService.updatePageSketch(
        pageModel.id!,
        pageModel.sketch,
      );
    } catch (e) {
      debugPrint('update sketch error: $e');
      debugPrint('falling back to old sketch');
      pageModel.sketch.updateWith(sketch: _oldSketch);
      rethrow;
    }
  }

  @override
  Future<void> queueUndo() async {
    try {
      await pageService.updatePageSketch(
        pageModel.id!,
        pageModel.sketch,
      );
    } catch (e) {
      debugPrint('update sketch error: $e');
      debugPrint('falling back to new sketch');
      pageModel.sketch.updateWith(sketch: _newSketch);
      rethrow;
    }
  }
}
