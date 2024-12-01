import 'dart:async';

import 'package:flutter/foundation.dart';

class TimerService with ChangeNotifier {
  TimerService({required this.interval});

  final int interval;
  Timer? _timer;
  // A list of callbacks that will be called on each timer tick.
  final List<VoidCallback> _tickListeners = [];

  void startTimer() {
    _timer?.cancel(); // Cancel any previous timer
    _timer = Timer.periodic(Duration(seconds: interval), (timer) {
      _notifyTickListeners();
    });
  }

  void stopTimer() {
    _timer = null;
    _timer?.cancel();
  }

  void _notifyTickListeners() {
    for (var listener in _tickListeners) {
      listener.call();
    }
  }

  // Allows widgets or other services to register callbacks.
  void addTickListener(VoidCallback listener) {
    _tickListeners.add(listener);
  }

  // Allows widgets or other services to remove registered callbacks.
  void removeTickListener(VoidCallback listener) {
    _tickListeners.remove(listener);
  }

  // Manual trigger that can also be called.
  void forceTrigger() {
    _notifyTickListeners();
  }

  @override
  void dispose() {
    _timer = null;
    stopTimer();

    super.dispose();
  }
}
