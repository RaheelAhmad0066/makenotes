import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/member/member_screen.dart';

class MemberLocation extends BeamLocation<BeamState> {
  MemberLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns => ['/*'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    return [
      BeamPage(
        type: BeamPageType.noTransition,
        child: MemberScreen(),
      ),
    ];
  }
}
