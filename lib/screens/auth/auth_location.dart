import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/utils/routes.dart';

import 'auth_screen.dart';

class AuthLocation extends BeamLocation<BeamState> {
  AuthLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [Routes.authScreen];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('auth'),
          title: 'Authentication',
          child: AuthScreen(),
        ),
      ];
}
