import 'package:flutter/foundation.dart';

import 'breadcrumb.model.dart';

class BreadcrumbWrapper extends ChangeNotifier {
  BreadcrumbWrapper({
    List<BreadcrumbModel>? prefixBreadcrumbs,
  }) {
    _breadcrumbs = prefixBreadcrumbs ?? [];
  }

  late List<BreadcrumbModel> _breadcrumbs;

  List<BreadcrumbModel> get breadcrumbs => [
        ..._breadcrumbs,
      ];

  @override
  void dispose() {
    _breadcrumbs = [];
    _breadcrumbs.clear();
    super.dispose();
  }

  void add(BreadcrumbModel breadcrumb) {
    _breadcrumbs.add(breadcrumb);
    notifyListeners();
  }

  void remove(BreadcrumbModel breadcrumb) {
    _breadcrumbs.remove(breadcrumb);
    notifyListeners();
  }

  void clear() {
    _breadcrumbs.clear();
    notifyListeners();
  }

  void addAll(List<BreadcrumbModel> breadcrumbs) {
    _breadcrumbs.addAll(breadcrumbs);
    notifyListeners();
  }

  void removeAfter(BreadcrumbModel breadcrumb) {
    final index = _breadcrumbs.indexOf(breadcrumb) + 1;
    if (index == 0 || index == _breadcrumbs.length) return;
    _breadcrumbs.removeRange(index, _breadcrumbs.length);
    notifyListeners();
  }
}
