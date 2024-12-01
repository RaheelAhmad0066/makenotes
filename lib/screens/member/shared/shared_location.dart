import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/member/shared/shared_screen.dart';
import 'package:makernote/services/item/shared.service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/utils/view_mode.dart';
import 'package:provider/provider.dart';

class SharedLocation extends BeamLocation<BeamState> {
  SharedLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [
        Routes.sharedScreen,
        '${Routes.sharedScreen}/:ownerId/*',
      ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        BeamPage(
          type: BeamPageType.noTransition,
          key: const ValueKey('shared'),
          title: 'Shared',
          child: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => SharedService()),
              ],
              builder: (context, snapshot) {
                return const SharedHomeScreen();
              }),
        ),
        if (state.pathParameters.containsKey('ownerId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey('shared-${state.pathParameters['ownerId']}'),
            title: 'Shared Documents',
            child: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => SharedService()),
                ],
                builder: (context, snapshot) {
                  return SharedByUserScreen(
                    ownerId: state.pathParameters['ownerId']!,
                  );
                }),
          ),
      ];
}

class SharedItemLocation extends BeamLocation<BeamState> {
  SharedItemLocation(
    RouteInformation super.routeInformation,
    this.ownerId,
    this.viewMode,
  );

  final String ownerId;
  final ValueNotifier<ViewMode> viewMode;

  @override
  List<String> get pathPatterns => [
        '${Routes.sharedScreen}/$ownerId/:itemId',
      ];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('shared-$ownerId-${state.pathParameters['itemId']}'),
          title: 'Shared Documents',
          child: SharedScreen(
            key: ValueKey('shared-$ownerId-${state.pathParameters['itemId']}'),
            ownerId: ownerId,
            folderId: state.pathParameters['itemId'],
            viewMode: viewMode,
          ),
        ),
      ];
}
