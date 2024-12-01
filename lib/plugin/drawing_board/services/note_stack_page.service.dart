import 'dart:async';

import 'package:flutter/material.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/digit_recognition/marking_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/services/item/page.service.dart';
import 'package:makernote/utils/async_operation/page_sync_manager.dart';
import 'package:rxdart/rxdart.dart';

class NoteStackPageService extends ChangeNotifier {
  NoteStackPageService({
    required this.noteService,
    required this.pageService,
    required this.noteStack,
    int initialCurrentPageIndex = 0,
    this.disableCache = false,
  }) {
    _accessibilityService = AccessibilityService();
    _syncPagesManager = SyncPagesManager(
      pageService: pageService,
      noteStack: noteStack,
    );
    _init();

    _currentPageIndexSubject =
        BehaviorSubject<int>.seeded(initialCurrentPageIndex);
  }

  final NoteService noteService;
  final PageService pageService;
  final NoteModelStack noteStack;
  final bool disableCache;

  late final SyncPagesManager _syncPagesManager;

  late final AccessibilityService _accessibilityService;

  final Map<String, List<PageModel>> _cachedPages = {};

  int get pageCount => _pageCount;
  int _pageCount = 0;

  // _isLoading valuenotifier
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  ValueNotifier<bool> get isLoadingNotifier => _isLoadingNotifier;

  // Timer for debouncing
  int _tempCurrentPageIndex = 0;
  final Debouncer _debouncer = Debouncer(milliseconds: 300, leading: true);

  int get currentPageIndex => _tempCurrentPageIndex;
  set currentPageIndex(int index) {
    if (_tempCurrentPageIndex == index) return;
    if (index < 0 || index >= pageCount) return;

    _tempCurrentPageIndex = index;

    // Set loading to true and notify listeners
    _isLoadingNotifier.value = true;

    // _debouncer.run(() {
    debugPrint('Setting current page index: $index');
    _currentPageIndexSubject.add(index);
    _isLoadingNotifier.value = false;
    notifyListeners();
    // });
  }

  bool get hasNextPage => currentPageIndex < pageCount - 1;
  bool get hasPreviousPage => currentPageIndex > 0;

  late final BehaviorSubject<int> _currentPageIndexSubject;

  bool get canInsertPage =>
      _accessibilityService.currentUserId == noteStack.template.ownerId &&
      noteStack.focusedNote?.noteType == NoteType.template;

  PageModel? get currentPage {
    debugPrint('Getting current page on note: ${noteStack.focusedNote!.id!}');
    debugPrint('Current page index: ${_currentPageIndexSubject.value}');
    var page = noteStack.hasFocus
        ? _cachedPages[noteStack.focusedNote!.id!]!
            .where((element) => element.order == _currentPageIndexSubject.value)
            .firstOrNull
        : null;

    if (page == null && noteStack.focusedNote?.id != null) {
      getCurrentPage(noteStack.focusedNote!.id!).then((value) {
        page = value;
        notifyListeners();
      });
    }

    return page;
  }

  _init() async {
    _pageCount = await pageService.getPageCount(
        noteStack.template.id!, noteStack.template.ownerId);
    notifyListeners();
  }

  @override
  dispose() {
    _currentPageIndexSubject.close();
    _debouncer.dispose();
    _isLoadingNotifier.dispose(); // Add this line
    _cachedPages.clear();
    super.dispose();
  }

  Future<List<PageModel>> getCurrentPages() async {
    // get the current page of all notes in the stack
    final pages = await Future.wait(noteStack.allNotes.map((note) async {
      return await getCurrentPage(note.id!);
    }));
    return pages;
  }

  Future<PageModel> getCurrentPage(String noteId) async {
    if (!noteStack.hasNote(noteId)) {
      throw Exception('Note $noteId is not in the stack');
    }

    PageModel? foundPage;
    if (_cachedPages.containsKey(noteId)) {
      debugPrint('Using cached pages');
      foundPage = _cachedPages[noteId]!
          .where((element) => element.order == _currentPageIndexSubject.value)
          .firstOrNull;
    }

    if (foundPage != null) {
      return foundPage;
    } else {
      debugPrint('Fetching pages from database');
      try {
        // sync number of pages to template
        final List<PageModel> syncedPages =
            await _syncPagesManager.syncPages(noteId);

        _pageCount = syncedPages.length;
        if (!disableCache) _cachedPages[noteId] = syncedPages;
        return syncedPages
            .where((element) => element.order == _currentPageIndexSubject.value)
            .first;
      } catch (e) {
        debugPrint('Error getting current pages: $e');
        rethrow;
      }
    }
  }

  Stream<PageModel> getCurrentPageStream(String noteId) {
    var controller = StreamController<PageModel>();
    StreamSubscription<PageModel>? pageStreamSubscription;
    StreamSubscription<int>? currentPageIndexStreamSubscription;

    currentPageIndexStreamSubscription = _currentPageIndexSubject.stream
        .debounceTime(const Duration(milliseconds: 300))
        .listen(
      (index) {
        debugPrint('Current page index changed: $index');

        // Cancel the previous subscription if it exists
        pageStreamSubscription?.cancel();

        // Subscribe to the new page stream
        pageStreamSubscription = pageService
            .getPageStream(noteId, index, noteStack.template.ownerId)
            .debounceTime(
              const Duration(milliseconds: 300),
            )
            .listen(
          (page) {
            debugPrint('Got page: ${page.id}');

            // Add the page to the controller's stream
            if (!controller.isClosed) {
              if (_cachedPages.containsKey(noteId)) {
                final pageIndex = _cachedPages[noteId]!
                    .indexWhere((element) => element.order == page.order);
                if (pageIndex != -1) {
                  final cachedPage = _cachedPages[noteId]!
                      .firstWhere((element) => element.order == page.order);
                  if (cachedPage.id == page.id) {
                    debugPrint('Updating cached page ${cachedPage.id}');
                    // update cached page
                    cachedPage.update(page);
                  }
                } else {
                  // add page to cache
                  _cachedPages[noteId]!.add(page);
                }
              } else {
                // add page to cache
                _cachedPages[noteId] = [page];
              }

              controller.add(page);
            }
          },
          onError: (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          },
        );
      },
      onDone: () {
        pageStreamSubscription?.cancel();
        pageStreamSubscription = null;
        // Close the controller when the currentPageIndexSubject stream is done
        controller.close();
      },
      onError: (e) {
        pageStreamSubscription?.cancel();
        pageStreamSubscription = null;
        // Add error to the controller if currentPageIndexSubject stream errors
        controller.addError(e);
      },
    );

    controller.onCancel = () {
      // Cancel the currentPageIndexSubject stream subscription when the controller's stream is cancelled
      currentPageIndexStreamSubscription?.cancel();
      currentPageIndexStreamSubscription = null;
      // Cancel the page stream subscription when the controller's stream is cancelled
      pageStreamSubscription?.cancel();
      pageStreamSubscription = null;
      // Close the controller to free up resources
      controller.close();
    };

    // Return the controller's stream
    return controller.stream;
  }

  Future<void> refreshCache() async {
    debugPrint('Refreshing cache');
    _cachedPages.clear();
    _pageCount = await pageService.getPageCount(
        noteStack.template.id!, noteStack.template.ownerId);
  }

  Future<void> cacheAllFocusedPages() async {
    if (!noteStack.hasFocus) return;

    if (!_cachedPages.containsKey(noteStack.focusedNote!.id!)) {
      debugPrint('Caching all focused pages: ${noteStack.focusedNote?.id}');
      final pages =
          await _syncPagesManager.syncPages(noteStack.focusedNote!.id!);

      _cachedPages[noteStack.focusedNote!.id!] = pages;

      // notifyListeners();
    }
  }

  // insert page
  Future<void> insertPage({required int index}) async {
    if (index < 0 || index > pageCount) return;
    if (!canInsertPage) return;

    try {
      // insert a page in the template note
      final newPage = await pageService.insertPage(
        noteId: noteStack.template.id!,
        position: index,
        ownerId: noteStack.template.ownerId,
      );

      // update cache
      if (_cachedPages.containsKey(noteStack.template.id!)) {
        _cachedPages[noteStack.template.id!]!.insert(index, newPage);

        // update page order
        for (var i = index + 1;
            i < _cachedPages[noteStack.template.id!]!.length;
            i++) {
          _cachedPages[noteStack.template.id!]![i].order = i;
        }
      }

      // insert a page in all the overlay notes
      await Future.wait(noteStack.overlays.map((overlay) async {
        var newOverlayPage = await pageService.insertPage(
            noteId: overlay.id!,
            position: index,
            ownerId: overlay.ownerId,
            page: PageModel(
              referenceId: newPage.id!,
            ));

        // update cache
        if (_cachedPages.containsKey(overlay.id!)) {
          _cachedPages[overlay.id!]!.insert(index, newOverlayPage);

          // update page order
          for (var i = index + 1; i < _cachedPages[overlay.id!]!.length; i++) {
            _cachedPages[overlay.id!]![i].order = i;
          }
        }
      }));

      _pageCount++;

      notifyListeners();
    } catch (e) {
      debugPrint('Error inserting page: $e');
    }
  }

  Future<void> updateFocusedPage({required PageModel page}) async {
    if (!canInsertPage) return;
    if (!noteStack.hasFocus) return;

    await pageService.updatePage(
      noteId: noteStack.focusedNote!.id!,
      page: page,
      ownerId: noteStack.focusedNote!.ownerId,
    );

    // update cache if the page is in the cache
    if (_cachedPages.containsKey(noteStack.focusedNote!.id!)) {
      _cachedPages[noteStack.focusedNote!.id!]!
          .where((element) => element.order == currentPageIndex)
          .first
          .update(page);
    }

    notifyListeners();
  }

  Future<void> deleteCurrentPage() async {
    if (!canInsertPage) return;

    try {
      // delete the page in the template note
      final currentPageOfTemplate =
          await getCurrentPage(noteStack.template.id!);
      await pageService.deletePage(
        noteId: noteStack.template.id!,
        pageId: currentPageOfTemplate.id!,
        ownerId: noteStack.template.ownerId,
      );

      // update cache
      if (_cachedPages.containsKey(noteStack.template.id!)) {
        _cachedPages[noteStack.template.id!]!
            .removeWhere((element) => element.order == currentPageIndex);

        // update page order
        for (var i = currentPageIndex;
            i < _cachedPages[noteStack.template.id!]!.length;
            i++) {
          _cachedPages[noteStack.template.id!]![i].order = i;
        }
      }

      // delete the page in all the overlay notes
      await Future.wait(
        noteStack.overlays.map((overlay) async {
          final currentPageOfOverlay = await getCurrentPage(overlay.id!);
          await pageService.deletePage(
            noteId: overlay.id!,
            pageId: currentPageOfOverlay.id!,
            ownerId: overlay.ownerId,
          );

          // update cache
          if (_cachedPages.containsKey(overlay.id!)) {
            _cachedPages[overlay.id!]!
                .removeWhere((element) => element.order == currentPageIndex);

            // update page order
            for (var i = currentPageIndex;
                i < _cachedPages[overlay.id!]!.length;
                i++) {
              _cachedPages[overlay.id!]![i].order = i;
            }
          }
        }),
      );

      _pageCount--;

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting page: $e');
    }
  }

  double getOverallMarkingScore() {
    final templateNote = noteStack.template;
    final targetNote = noteStack.getNoteByNoteType(NoteType.marking);

    if (targetNote == null) return 0;

    final markings = templateNote.markings?.map((element) {
          final focusedMarking = targetNote.markings?.firstWhere(
            (marking) => marking.markingId == element.markingId,
            orElse: () => element,
          );
          return focusedMarking;
        }).toList() ??
        [];

    return markings.fold<double>(0, (previousValue, element) {
      return previousValue + (element?.score ?? 0);
    });
  }

  Future<List<MarkingModel>> getCurrentMarkings(
      {bool getMarking = false}) async {
    final targetNode = getMarking == true
        ? noteStack.getNoteByNoteType(NoteType.marking)
        : noteStack.focusedNote ??
            noteStack.getNoteByNoteType(NoteType.marking);
    if (targetNode == null) return [];

    debugPrint('get template page: ${noteStack.template.id!}');

    final templatePage = await getCurrentPage(noteStack.template.id!);

    debugPrint('get focused page: ${noteStack.focusedNote!.id!}');

    final currentPage = await getCurrentPage(noteStack.focusedNote!.id!);

    final templatePageMarkings = noteStack.template.markings?.where((element) {
          return element.pageId == templatePage.id ||
              element.pageId == templatePage.referenceId;
        }).toList() ??
        [];

    final currentPageMarkings = targetNode.markings?.where((element) {
      return element.pageId == currentPage.id ||
          element.pageId == currentPage.referenceId;
    }).toList();

    debugPrint('Template page markings: ${templatePageMarkings.length}');

    final pageMarkings = <MarkingModel>[];
    for (var i = 0; i < templatePageMarkings.length; i++) {
      final templateMarking = templatePageMarkings[i];
      debugPrint('Template marking: ${templateMarking.markingId}');
      final currentPageMarking = currentPageMarkings?.firstWhere(
        (element) => element.markingId == templateMarking.markingId,
        orElse: () => templateMarking,
      );
      debugPrint('Current page marking: ${currentPageMarking?.markingId}');

      pageMarkings.add(currentPageMarking ?? templateMarking);
    }

    return pageMarkings;
  }

  Future<void> updateCurrentPageMarkings({
    required List<MarkingModel> markings,
  }) async {
    if (!noteStack.hasFocus) return Future.value();

    final currentPage = _cachedPages[noteStack.focusedNote!.id!]!
        .where((element) => element.order == currentPageIndex)
        .first;

    final focusedNode = noteStack.focusedNote!;

    // save the original markings
    final originMarkings = focusedNode.markings ?? [];

    // filter not current page model markings
    final nonCurrentPageMarkings = focusedNode.markings?.where((element) {
      return element.pageId != currentPage.id &&
          element.pageId != currentPage.referenceId;
    }).toList();

    // append new markings
    final updatedMarkings = <MarkingModel>[
      ...nonCurrentPageMarkings ?? [],
      ...markings
    ];

    // update the focused note
    noteStack.focusedNote?.setMarkings(updatedMarkings);

    // update the focused note in the database
    try {
      await noteService.setMarkings(
        note: focusedNode,
        pageId: currentPage.id!,
        referenceId: currentPage.referenceId,
        markings: markings,
      );
    } catch (e) {
      // revert the changes
      noteStack.focusedNote?.setMarkings(originMarkings);
      rethrow;
    }
  }
}
