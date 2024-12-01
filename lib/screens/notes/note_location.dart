import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:makernote/screens/notes/note_screen.dart';
import 'package:makernote/services/item/graphic_element.service.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/services/item/page.service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:provider/provider.dart';

class NoteLocation extends BeamLocation<BeamState> {
  NoteLocation(RouteInformation super.routeInformation);

  @override
  List<String> get pathPatterns =>
      ['${Routes.noteScreen}/:noteId', '${Routes.noteScreen}/:noteId/:ownerId'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        if (state.pathParameters.containsKey('noteId') &&
            state.pathParameters.containsKey('ownerId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey(
                'note-${state.pathParameters['noteId']}-${state.pathParameters['ownerId']}'),
            title: 'Note',
            child: MultiProvider(
              providers: [
                Provider(create: (_) => PageService()),
                Provider(create: (_) => GraphicElementService()),
                Provider(create: (_) => MCService()),
              ],
              builder: (context, child) {
                return NoteScreen(
                  noteId: state.pathParameters['noteId'],
                  ownerId: state.pathParameters['ownerId'],
                );
              },
            ),
          )
        else if (state.pathParameters.containsKey('noteId'))
          BeamPage(
            type: BeamPageType.noTransition,
            key: ValueKey('note-${state.pathParameters['noteId']}'),
            title: 'Note',
            child: MultiProvider(
              providers: [
                Provider(create: (_) => PageService()),
                Provider(create: (_) => GraphicElementService()),
                Provider(create: (_) => MCService()),
              ],
              builder: (context, child) {
                return NoteScreen(
                  noteId: state.pathParameters['noteId'],
                );
              },
            ),
          ),
      ];
}
