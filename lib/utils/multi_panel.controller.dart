import 'package:flutter/material.dart';

class MultiPanelController extends ChangeNotifier {
  MultiPanelController._(Map<String, bool> panelOpenStates)
      : _panelOpenStates = panelOpenStates;

  factory MultiPanelController.fromNames(List<String> panelIds,
      {String? defaultOpen}) {
    final panelOpenStates = <String, bool>{};
    for (final panelId in panelIds) {
      panelOpenStates[panelId] = false;
    }
    if (defaultOpen != null) {
      panelOpenStates[defaultOpen] = true;
    }
    return MultiPanelController._(panelOpenStates);
  }

  // A map to keep track of the open state of each panel
  final Map<String, bool> _panelOpenStates;

  // Function to open a specific panel
  void openPanel(String panelId) {
    // Close all panels
    _panelOpenStates.updateAll((key, value) => false);
    // Open the specified panel
    _panelOpenStates[panelId] = true;

    notifyListeners();
  }

  // Function to close a specific panel
  void closePanel(String panelId) {
    _panelOpenStates[panelId] = false;

    notifyListeners();
  }

  // Function to check if a specific panel is open
  bool isPanelOpen(String panelId) {
    return _panelOpenStates[panelId] ?? false;
  }
}
