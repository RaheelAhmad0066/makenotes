import 'package:flutter/foundation.dart';

class BreadcrumbModel extends ChangeNotifier {
  final String label;
  final String route;

  BreadcrumbModel({
    required this.label,
    required this.route,
  });

  @override
  void dispose() {
    // Perform any additional cleanup here if needed
    super.dispose();
  }
}
