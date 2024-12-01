import 'package:flutter/material.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/services/item/page.service.dart';

import 'async_operation_manager.dart';

class SyncPagesManager extends AsyncOperationManager<List<PageModel>> {
  SyncPagesManager({
    required this.pageService,
    required this.noteStack,
  });

  final PageService pageService;
  final NoteModelStack noteStack;

  Future<List<PageModel>> syncPages(String noteId) async {
    return performOperation(noteId, () => _performSyncPages(noteId));
  }

  Future<List<PageModel>> _performSyncPages(String noteId) async {
    debugPrint('Syncing pages for note $noteId');
    final noteModel =
        noteStack.allNotes.where((element) => element.id == noteId).firstOrNull;
    if (noteModel == null) {
      throw Exception('Note $noteId is not in the stack');
    }

    if (noteId == noteStack.template.id) {
      return await pageService.getPages(noteId, noteStack.template.ownerId);
    }

    final templatePages = await pageService.getPages(
        noteStack.template.id!, noteStack.template.ownerId);
    final overlayPages = await pageService.getPages(noteId, noteModel.ownerId);

    debugPrint('Template pages: ${templatePages.length}');
    debugPrint('Overlay pages: ${overlayPages.length}');

    final templatePageMap = {for (var page in templatePages) page.id!: page};
    final overlayPageMap = {
      for (var page in overlayPages) page.referenceId: page
    };

    final syncedPages = <PageModel>[];
    final deletePageFutures = <Future>[];

    for (final templatePage in templatePages) {
      debugPrint('Syncing page from template: ${templatePage.id}');
      final overlayPage = overlayPageMap[templatePage.id];
      if (overlayPage == null) {
        final newPage = await pageService.insertPage(
          noteId: noteId,
          position: templatePage.order,
          ownerId: noteModel.ownerId,
          page: PageModel(referenceId: templatePage.id!),
        );
        syncedPages.add(newPage);
      } else {
        syncedPages.add(overlayPage);
      }
    }

    for (final overlayPage in overlayPages) {
      if (!templatePageMap.containsKey(overlayPage.referenceId)) {
        deletePageFutures.add(pageService.deletePage(
          noteId: noteId,
          pageId: overlayPage.id!,
          ownerId: noteModel.ownerId,
        ));
      }
    }

    await Future.wait(deletePageFutures);

    return syncedPages;
  }
}
