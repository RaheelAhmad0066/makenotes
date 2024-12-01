import 'package:makernote/models/note_model.dart';

abstract class INoteService {
  Future<NoteModel> getNote(String noteId, String? ownerId);
  Stream<NoteModel> getNoteStream(String noteId, String? ownerId);
  Future<void> createOverlayNote(String name, String overlayOn);
}
