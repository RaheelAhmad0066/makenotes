import 'package:flutter/material.dart';

class Routes {
  static const String notFound = '/not-found';
  static const String homeScreen = '/';
  static const String splashScreen = '/splash';
  static const String authScreen = '/auth';
  static const String documentScreen = '/document';
  static const String noteScreen = '/note';
  static const String trashScreen = '/trash';
  static const String accountScreen = '/account';
  static const String joinItemScreen = '/join-item';
  static const String sharedScreen = '/shared';
  static const String overviewScreen = '/overview';
  static const String testScreen = '/test';

  static const List<String> allRoutes = [
    notFound,
    homeScreen,
    splashScreen,
    authScreen,
    documentScreen,
    noteScreen,
    trashScreen,
    accountScreen,
    joinItemScreen,
    sharedScreen,
    overviewScreen,
    testScreen,
  ];

  static bool isActive(RouteInformation routeInformation, String route) {
    return routeInformation.uri.pathSegments.contains(route.split('/')[1]);
  }
}
