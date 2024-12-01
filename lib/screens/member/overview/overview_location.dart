import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/utils/routes.dart';

import 'overview_screen.dart';

class OverviewLocation extends BeamLocation<BeamState> {
  OverviewLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [
        '${Routes.overviewScreen}/:noteId',
        '${Routes.overviewScreen}/:noteId/:ownerId'
      ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        if (state.pathParameters.containsKey('noteId') &&
            state.pathParameters.containsKey('ownerId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey(
                'overview-${state.pathParameters['noteId']}-${state.pathParameters['ownerId']}'),
            title: 'Note Overview',
            child: OverviewScreen(
              noteId: state.pathParameters['noteId']!,
              ownerId: state.pathParameters['ownerId'],
            ),
          )
        else if (state.pathParameters.containsKey('noteId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey('overview-${state.pathParameters['noteId']}'),
            title: 'Note Overview',
            child: OverviewScreen(
              noteId: state.pathParameters['noteId']!,
            ),
          ),
      ];
}
