import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;
  bool _isFirstAction = true;
  late bool _leading;

  Debouncer({
    required this.milliseconds,
    bool leading = false,
  }) {
    _isFirstAction = !leading;
    _leading = leading;
  }

  run(VoidCallback action) {
    if (_isFirstAction) {
      action();
      _isFirstAction = false;
    } else {
      if (_timer != null) {
        _timer!.cancel();
      }
      isLoadingNotifier.value = true;
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        isLoadingNotifier.value = false;
        action();
        _isFirstAction = _leading; // Reset the flag for the next first action
      });
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    action = null;
    isLoadingNotifier.dispose();
  }
}
