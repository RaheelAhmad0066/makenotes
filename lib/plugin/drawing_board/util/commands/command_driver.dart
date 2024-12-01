import 'package:flutter/foundation.dart';

import 'command.dart';

class CommandDriver extends ChangeNotifier {
  final List<Command> _commands = [];
  int _currentCommandIndex = 0;
  final List<Future<void> Function()> _commandQueue = [];
  bool _isProcessingQueue = false;

  bool get canExecute => true;
  bool get canUndo => _commands.isNotEmpty && _currentCommandIndex > 0;
  bool get canRedo =>
      _commands.isNotEmpty && _currentCommandIndex < _commands.length;

  bool get processingQueue => _isProcessingQueue;
  double? get progress =>
      _commands.isNotEmpty ? _commandQueue.length / _commands.length : null;
  List<Command> get commands => _commands.toList();

  int get currentIndex => _currentCommandIndex;
  int get length => _commands.length;

  Future<void> _processQueue() async {
    debugPrint(
        '/==================== processing queue ====================\\\n');
    _isProcessingQueue = true;
    notifyListeners();
    while (_commandQueue.isNotEmpty) {
      debugPrint('processing command queue: ${_commandQueue.length}');
      var command = _commandQueue.removeAt(0);
      try {
        await command();
      } catch (e) {
        debugPrint('command error: $e');
        rethrow;
      }
      debugPrint('remaining command queue: ${_commandQueue.length}');
    }
    _isProcessingQueue = false;
    notifyListeners();
    debugPrint('\\==================== processing queue ====================/');
  }

  /// Append and execute a command
  void execute(Command command) {
    if (!canExecute) return;

    command.execute();

    // remove all commands after the current command
    _commands.removeRange(_currentCommandIndex, _commands.length);
    _commands.add(command);
    _currentCommandIndex++;

    _queueExecute(command);

    notifyListeners();
  }

  /// Append and undo a command
  void undo() {
    if (!canUndo) return;

    _currentCommandIndex--;

    _commands[_currentCommandIndex].undo();

    _queueUndo(_currentCommandIndex);

    notifyListeners();
  }

  /// Append and redo a command
  void redo() {
    if (!canRedo) return;

    _commands[_currentCommandIndex].execute();

    _queueRedo(_currentCommandIndex);

    _currentCommandIndex++;

    notifyListeners();
  }

  /// Add a command's execute to the queue
  Future<void> _queueExecute(Command command) async {
    _commandQueue.add(() async {
      await command.queueExecute();
    });

    if (!_isProcessingQueue) {
      await _processQueue();
    }
  }

  /// Add a command's undo to the queue
  Future<void> _queueUndo(int commandIndex) async {
    _commandQueue.add(() async {
      try {
        await _commands[commandIndex].queueUndo();
      } catch (e) {
        debugPrint('undo error: $e');
        rethrow;
      }
    });

    if (!_isProcessingQueue) {
      await _processQueue();
    }
  }

  /// Add a command's redo to the queue
  Future<void> _queueRedo(int commandIndex) async {
    _commandQueue.add(() async {
      try {
        await _commands[commandIndex].queueExecute();
      } catch (e) {
        debugPrint('redo error: $e');
        rethrow;
      }
    });

    if (!_isProcessingQueue) {
      await _processQueue();
    }
  }

  // Dispose
  @override
  void dispose() {
    _commands.clear();
    _commandQueue.clear();
    super.dispose();
  }
}
