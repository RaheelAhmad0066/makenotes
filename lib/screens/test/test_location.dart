import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/utils/routes.dart';

import 'test_screen.dart';

class TestLocation extends BeamLocation<BeamState> {
  TestLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [Routes.testScreen];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('test'),
          title: 'Test',
          child: TestScreen(),
        ),
      ];
}
