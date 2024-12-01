import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/auth/auth_location.dart';
import 'package:makernote/screens/member/member_location.dart';
import 'package:makernote/screens/notes/note_location.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:provider/provider.dart';

import 'test/test_location.dart';

final beamerKey = GlobalKey<BeamerState>();

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _routerDelegate = BeamerDelegate(
    guards: [
      BeamGuard(
        pathPatterns: [
          Routes.authScreen,
        ],
        guardNonMatching: true,
        check: (context, state) {
          final authService =
              Provider.of<AuthenticationService>(context, listen: false);
          if (authService.isLoading) {
            return true;
          }
          // Don't redirect if the target route is the authScreen route
          if (state.pathPatterns.contains(Routes.authScreen.split('/')[1])) {
            return true;
          }
          return authService.isLoggedIn;
        },
        beamToNamed: (origin, target) => Routes.authScreen,
      )
    ],
    locationBuilder: (routeInformation, _) {
      if (Routes.isActive(routeInformation, Routes.authScreen)) {
        return AuthLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.noteScreen)) {
        return NoteLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.testScreen)) {
        return TestLocation(routeInformation);
      } else {
        return MemberLocation(routeInformation);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Beamer(
      key: beamerKey,
      routerDelegate: _routerDelegate,
    );
  }
}
