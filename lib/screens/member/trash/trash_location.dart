import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/views/trash_view.dart';

class TrashLocation extends BeamLocation<BeamState> {
  TrashLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [Routes.trashScreen];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('trash'),
          title: 'Trash',
          child: TrashView(),
        ),
      ];
}
