import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';

class HomeLocation extends BeamLocation<BeamState> {
  HomeLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => ['/*'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    AuthenticationService authenticationService =
        Provider.of<AuthenticationService>(context);
    return [
      BeamPage(
        type: BeamPageType.noTransition,
        key: ValueKey('home-${DateTime.now()}'),
        title: 'Home',
        child: StreamBuilder(
          stream: authenticationService.userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return HomeScreen();
            }
          },
        ),
      ),
    ];
  }
}
