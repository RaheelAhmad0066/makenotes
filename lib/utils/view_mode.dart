import 'package:flutter/material.dart';

enum ViewMode {
  /// The view is a list of items.
  list,

  /// The view is a grid of items.
  grid,
}

// view mode wrapper of ChangeNotifier
class ViewModeNotifier extends ChangeNotifier {
  ViewModeNotifier(this._viewMode);

  ViewMode _viewMode;

  ViewMode get viewMode => _viewMode;

  set viewMode(ViewMode viewMode) {
    _viewMode = viewMode;
    notifyListeners();
  }
}
