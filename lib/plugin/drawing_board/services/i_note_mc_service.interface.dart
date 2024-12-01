import 'package:makernote/models/note_mc.model.dart';

abstract class INoteMCService {
  String? getUserId();

  Future<List<NoteMCModel>> getMC(String noteId, String? ownerId);
  Stream<List<NoteMCModel>> getMCStream(String noteId, String? ownerId);

  Future<void> appendMC(String noteId, int amount, String? ownerId);

  Future<void> updateMC(
      String noteId, int index, NoteMCModel mc, String? ownerId);

  Future<void> deleteMC(String noteId, int from, int to, String? ownerId);
}
