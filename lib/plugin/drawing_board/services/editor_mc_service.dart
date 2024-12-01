import 'package:flutter/foundation.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/services/i_note_mc_service.interface.dart';

class EditorMCService extends ChangeNotifier {
  EditorMCService({
    required this.noteMCService,
    required this.note,
    this.ownerId,
  });

  final INoteMCService noteMCService;
  final NoteModel note;
  final String? ownerId;

  bool get isOwner => ownerId == null || ownerId == noteMCService.getUserId();

  bool get hasOverlayNote => note.overlayOn != null;

  Future<List<NoteMCModel>> getMC() async {
    return await noteMCService.getMC(note.id!, ownerId);
  }

  Stream<List<NoteMCModel>> getMCStream() {
    return noteMCService.getMCStream(note.id!, ownerId);
  }

  void appendMC(int amount) {
    if (!isOwner) {
      return;
    }
    if (note.noteType != NoteType.template) {
      return;
    }
    noteMCService.appendMC(note.id!, amount, ownerId);

    final children = note.overlayedBy;
    for (final child in children) {
      noteMCService.appendMC(child.noteId, amount, child.ownerId);
    }
  }

  void updateMC(int index, NoteMCModel mc) {
    noteMCService.updateMC(note.id!, index, mc, ownerId);
  }

  void deleteMC({
    required int from,
    required int to,
  }) {
    if (!isOwner) {
      return;
    }
    if (note.noteType != NoteType.template) {
      return;
    }
    noteMCService.deleteMC(note.id!, from, to, ownerId);

    final children = note.overlayedBy;
    for (final child in children) {
      noteMCService.deleteMC(child.noteId, from, to, child.ownerId);
    }
  }
}
