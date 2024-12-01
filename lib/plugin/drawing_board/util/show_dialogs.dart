import 'package:flutter/material.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/dialogs/explanation.dialog.dart';
import 'package:provider/provider.dart';

import '../models/video_element_model.dart';
import 'widgets/dialogs/video.dialog.dart';

Future showExplanationDialog({
  required BuildContext context,
  required ExplanationElementModel explanationElement,
  required String noteId,
  EditorController? controller,
}) async {
  final noteStack = Provider.of<NoteModelStack>(context, listen: false);
  return showDialog(
    context: context,
    builder: (context) {
      return ExplanationDialog(
        explanationElement: explanationElement,
        controller: controller,
        noteId: noteId,
        noteStack: noteStack,
      );
    },
  );
}

Future showVideoDialog({
  required BuildContext context,
  required VideoElementModel videoElement,
  required String noteId,
  EditorController? controller,
}) async {
  final noteStack = Provider.of<NoteModelStack>(context, listen: false);
  return showDialog(
    context: context,
    builder: (context) {
      return VideoDialog(
        videoElement: videoElement,
        controller: controller,
        noteId: noteId,
        noteStack: noteStack,
      );
    },
  );
}
