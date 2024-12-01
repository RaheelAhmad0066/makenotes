abstract class Command {
  Command();

  void execute();

  void undo();

  /// Add the command to the queue
  Future<void> queueExecute();

  /// Add the command to the queue
  Future<void> queueUndo();
}
