import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/utils/routes.dart';
import 'join_item_screen.dart';

class JoinItemLocation extends BeamLocation<BeamState> {
  JoinItemLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns =>
      [Routes.joinItemScreen, '${Routes.joinItemScreen}/:token'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('join-item'),
          title: 'Join Note',
          child: JoinItemScreen(),
        ),
        if (state.pathParameters.containsKey('token'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey('join-item-${state.pathParameters['token']}'),
            title: 'Join Note',
            child: JoinItemScreen(
              token: state.pathParameters['token'],
            ),
          ),
      ];
}
