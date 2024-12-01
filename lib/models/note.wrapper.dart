import 'package:flutter/material.dart';
import 'package:makernote/models/note_model.dart';

class NoteWrapper extends ChangeNotifier {
  NoteModel? get note => _note;
  NoteModel? _note;
  set note(NoteModel? note) {
    _note = note;
    notifyListeners();
  }

  @override
  void dispose() {
    note?.dispose();
    super.dispose();
  }
}
