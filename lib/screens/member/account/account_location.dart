import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/member/account/account_screen.dart';
import 'package:makernote/utils/routes.dart';

class AccountLocation extends BeamLocation<BeamState> {
  AccountLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => [Routes.accountScreen];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('account'),
          title: 'Account',
          child: AccountScreen(),
        ),
      ];
}
