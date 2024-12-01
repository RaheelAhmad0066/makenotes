import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/member/document/document_screen.dart';
import 'package:makernote/utils/routes.dart';

class DocumentsLocation extends BeamLocation<BeamState> {
  DocumentsLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns =>
      [Routes.documentScreen, '${Routes.documentScreen}/:folderId'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        const BeamPage(
          type: BeamPageType.noTransition,
          key: ValueKey('documents'),
          title: 'Documents',
          child: DocumentScreen(),
        ),
        if (state.pathParameters.containsKey('folderId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey('documents-${state.pathParameters['folderId']}'),
            title: 'Documents',
            child: DocumentScreen(
              folderId: state.pathParameters['folderId'],
            ),
          ),
      ];
}
