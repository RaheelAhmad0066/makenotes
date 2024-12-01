import 'dart:async';

import 'dart:io';
import 'package:makernote/services/user.service.dart';
import 'package:universal_html/html.dart' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/digit_recognition/marking_model.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/page.service.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/access_right.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class NoteService extends ItemService<NoteModel> {
  NoteService() : super();

  @override
  Future<String> addItem(String name, {String? parentId}) async {
    // check usage limit
    if (await isUsageLimitReached()) {
      throw Exception('Usage limit reached');
    }

    // check if name already exists
    name = await getNextName(name, ItemType.note, parentId: parentId);

    final newNote = await db
        .collection('users')
        .doc(getUserId())
        .collection(ItemService.collectionName)
        .add(NoteModel(
          ownerId: getUserId()!,
          name: name,
          parentId: parentId,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          createdBy: getUserId()!,
        ).toMap());

    // append a page to the new note
    await newNote.collection(PageService.pagesCollectionName).add(
          PageModel(
            order: 0,
          ).toMap(),
        );

    return newNote.id;
  }

  Future<NoteModel> getNote(String noteId, String? ownerId) async {
    try {
      return await db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .get()
          .then((snapshot) => NoteModel.fromFirestore(snapshot));
    } catch (e) {
      debugPrint("Error getting note: $e");
      rethrow;
    }
  }

  Stream<NoteModel> getNoteStream(String noteId, String? ownerId) {
    try {
      return db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .snapshots()
          .map((snapshot) => NoteModel.fromFirestore(snapshot));
    } catch (e) {
      debugPrint("Error getting note stream: $e");
      rethrow;
    }
  }

  /// Creates a new note on the root level that overlays on a shared note.
  Future<NoteModel> createOverlayNote(
    NoteModel overlayOn,
    NoteType noteType,
  ) async {
    try {
      // Create callable
      final callable =
          FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
        'createOverlayNote',
      );

      // Map of the a new note
      var noteMap = NoteModel(
        ownerId: overlayOn.ownerId,
        name: overlayOn.name,
        noteType: noteType,
        parentId: overlayOn.parentId,
        overlayOn: NoteReferenceModel.fromNoteModel(overlayOn),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        createdBy: getUserId()!,
        multipleChoices: overlayOn.multipleChoices
                ?.map((e) => NoteMCModel.empty())
                .toList() ??
            [],
        markings: overlayOn.markings?.toList() ?? [],
      ).toMap();

      noteMap['createdAt'] =
          (noteMap['createdAt'] as Timestamp).millisecondsSinceEpoch;
      noteMap['updatedAt'] =
          (noteMap['updatedAt'] as Timestamp).millisecondsSinceEpoch;
      noteMap['multipleChoices'] = noteMap['multipleChoices']
          .map((e) => {
                'correctAnswer': e['correctAnswer'],
                'createdAt':
                    (e['createdAt'] as Timestamp).millisecondsSinceEpoch,
                'updatedAt':
                    (e['updatedAt'] as Timestamp).millisecondsSinceEpoch,
              })
          .toList(growable: false);

      // Call the function
      final newNoteResponse = await callable.call<dynamic>(
        {
          'ownerId': overlayOn.ownerId,
          'itemId': overlayOn.id,
          'noteModel': noteMap,
        },
      );

      // Get the new note
      final newNote =
          NoteModel.fromMap(Map<String, dynamic>.from(newNoteResponse.data));

      // gant read access to overlayOn's creator if it's not the same as the new note's owner
      if (newNote.ownerId != overlayOn.createdBy) {
        await AccessibilityService().grantAccessRight(
          itemId: newNote.id!,
          ownerId: overlayOn.ownerId,
          userId: overlayOn.createdBy,
          rights: [AccessRight.read],
        );
      }

      debugPrint('Created new note with id: ${newNote.id}');

      return newNote;
    } catch (e) {
      debugPrint('Error creating overlay note: $e');
      rethrow;
    }
  }

  // set hide explanation
  Future<void> setHideExplanation({
    required NoteModel note,
    required bool hideExplanation,
  }) async {
    try {
      await db
          .collection('users')
          .doc(note.ownerId)
          .collection(ItemService.collectionName)
          .doc(note.id)
          .update({
        'hideExplanation': hideExplanation,
      });
    } catch (e) {
      debugPrint('Error setting hide explanation: $e');
      rethrow;
    }
  }

  // set note markings
  Future<void> setMarkings({
    required NoteModel note,
    required String pageId,
    required String? referenceId,
    required List<MarkingModel> markings,
  }) async {
    try {
      // get the note from firestore
      final noteRef = await db
          .collection('users')
          .doc(note.ownerId)
          .collection(ItemService.collectionName)
          .doc(note.id)
          .get();
      final noteModel = NoteModel.fromFirestore(noteRef);

      // get a list of markings that are not in the page
      final markingsFromOtherPages = noteModel.markings
          ?.where((marking) =>
              marking.pageId != pageId && marking.pageId != referenceId)
          .toList();

      // add the new markings to the list
      final newMarkings = [...markingsFromOtherPages ?? [], ...markings];

      // update the note with the new markings
      await db
          .collection('users')
          .doc(note.ownerId)
          .collection(ItemService.collectionName)
          .doc(note.id)
          .update({
        'markings': newMarkings.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error setting markings: $e');
      rethrow;
    }
  }

  // set note to be [locked] or not
  Future<void> setLock({
    required NoteModel note,
    required bool locked,
    required Timestamp? lockedAt,
  }) async {
    try {
      await db
          .collection('users')
          .doc(note.ownerId)
          .collection(ItemService.collectionName)
          .doc(note.id)
          .update({
        'locked': locked,
        'lockedAt': locked ? lockedAt : null,
      });
    } catch (e) {
      debugPrint('Error setting lock: $e');
      rethrow;
    }
  }

  // start marking the note
  Future<void> startMarking({
    required NoteModel exerciseNote,
  }) async {
    try {
      if (exerciseNote.noteType != NoteType.exercise) {
        throw Exception('Note is not an exercise');
      }

      // set the note to be locked
      await setLock(
          note: exerciseNote, locked: true, lockedAt: Timestamp.now());

      // check if the note has marking overlay
      final overlays = await getOverlayNotes(
        noteId: exerciseNote.id!,
        type: NoteType.marking,
      );
      var markingNote = overlays.firstOrNull;

      // create a new marking overlay note if not exists
      markingNote ??= await createOverlayNote(
        exerciseNote,
        NoteType.marking,
      );

      // set the marking overlay note to be locked with null lockedAt
      await setLock(note: markingNote, locked: true, lockedAt: null);
    } catch (e) {
      debugPrint('Error starting marking: $e');
      rethrow;
    }
  }

  // start marking all overlay notes
  Future<void> startMarkingAll({
    required NoteModel templateNote,
  }) async {
    try {
      // Create callable
      final callable =
          FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
        'lockMarkingNotes',
      );

      final response = await callable.call<dynamic>(
        {
          'templateId': templateNote.id,
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      debugPrint('Error starting marking all: $e');
      rethrow;
    }
  }

  Future<List<NoteModel>> getOverlayNotes({
    required String noteId,
    NoteType? type,
  }) async {
    try {
      var query = db
          .collection('users')
          .doc(getUserId())
          .collection(ItemService.collectionName)
          .where('overlayOn.noteId', isEqualTo: noteId);
      if (type != null) {
        query = query.where('noteType', isEqualTo: type.index);
      }

      // order by createdAt
      query = query.orderBy('createdAt');

      return await query.get().then((snapshot) =>
          snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error getting overlay notes: $e');
      rethrow;
    }
  }

  // lock all overlay notes
  Future<void> lockOverlayNotes({
    required String noteId,
    required bool locked,
    required Timestamp? lockedAt,
    NoteType? type = NoteType.exercise,
  }) async {
    try {
      var overlayNotes = await getOverlayNotes(noteId: noteId, type: type);
      await Future.wait(
        overlayNotes.map((note) => setLock(
              note: note,
              locked: locked,
              lockedAt: lockedAt,
            )),
      );
    } catch (e) {
      debugPrint('Error locking overlay notes: $e');
      rethrow;
    }
  }

  // get all overylay notes stream
  Stream<List<NoteModel>> getOverlayNotesStream({
    required String noteId,
    NoteType? type,
  }) async* {
    try {
      var query = db
          .collection('users')
          .doc(getUserId())
          .collection(ItemService.collectionName)
          .where('overlayOn.noteId', isEqualTo: noteId);
      if (type != null) {
        query = query.where('noteType', isEqualTo: type.index);
      }

      // order by createdAt
      query = query.orderBy('createdAt');

      // Cache to store the last emitted list of notes
      List<NoteModel>? lastEmittedNotes;

      // Listen to the Firestore stream
      var snapshots = query.snapshots();
      await for (var snapshot in snapshots) {
        var currentNotes =
            snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList();

        if (currentNotes.isEmpty && lastEmittedNotes == null) {
          lastEmittedNotes = currentNotes;
          yield currentNotes;
          continue;
        }

        // Check if there are changes in the fields of interest
        bool hasChanges = false;
        if (lastEmittedNotes == null ||
            currentNotes.length != lastEmittedNotes.length) {
          hasChanges = true;
        } else {
          for (int i = 0; i < currentNotes.length; i++) {
            if (!currentNotes[i].compare(lastEmittedNotes[i])) {
              hasChanges = true;
              break;
            }
          }
        }

        if (hasChanges) {
          lastEmittedNotes = currentNotes;
          yield currentNotes;
        }
      }
    } catch (e) {
      debugPrint('Error getting overlay notes stream: $e');
      // Handle or rethrow the exception as needed
      rethrow;
    }
  }

  // get all nested notes
  Future<NoteModelStack> getNestedNotes({
    required String noteId,
    String? ownerId,
  }) async {
    try {
      final note = await getNote(
        noteId,
        ownerId,
      );

      if (note.noteType == NoteType.template) {
        final stack = NoteModelStack(template: note);

        // check accessiblity
        final accessibilityService = AccessibilityService();
        bool accessible = await accessibilityService.checkAccessRight(
          itemId: note.id!,
          ownerId: note.ownerId,
          right: AccessRight.write,
        );

        if (!accessible) {
          stack.clearFocus();
        }

        return stack;
      } else {
        NoteModel? template;
        List<NoteModel> overlays = [];

        // search for the template
        NoteModel? pointer;
        int breaker = 0;
        while (pointer == null || pointer.noteType != NoteType.template) {
          pointer = await getNote(
            note.overlayOn!.noteId,
            note.overlayOn!.ownerId,
          );

          if (pointer.noteType == NoteType.template) {
            template = pointer;
          } else {
            overlays.add(pointer);
          }

          if (breaker++ > 100) {
            throw Exception('Template not found');
          }
        }

        // reverse the overlays list
        overlays = overlays.reversed.toList();

        // add self to overlays
        overlays.add(note);

        // reset pointer
        pointer = null;

        // find the nested notes
        breaker = 0;
        do {
          var noteRef = (pointer ?? note).overlayedBy.firstOrNull;
          if (noteRef != null) {
            try {
              pointer = await getNote(
                noteRef.noteId,
                noteRef.ownerId,
              );
              overlays.add(pointer);
            } catch (e) {
              debugPrint('Error getting nested note: $e\n'
                  '\t noteId: ${noteRef.noteId}\n'
                  '\t ownerId: ${noteRef.ownerId}');
              pointer = null;
            }
          } else {
            pointer = null;
          }

          if (breaker++ > 100) {
            throw Exception('Nested notes not found');
          }
        } while (pointer != null);

        if (template == null) {
          throw Exception('Template not found');
        }

        final stack = NoteModelStack(template: template, overlays: overlays);

        stack.focusOverlayByCreator(getUserId()!);

        return stack;
      }
    } catch (e) {
      debugPrint('Error getting nested notes: $e');
      rethrow;
    }
  }

  // get all nested notes stream
  StreamController<NoteModelStack> getNestedNotesStream({
    required String noteId,
    String? ownerId,
  }) {
    var controller = StreamController<NoteModelStack>();
    List<StreamSubscription<NoteModel>> noteSubscriptions = [];

    void handleNoteStack(NoteModelStack stack) {
      // TODO: add logic to store the last emitted stack and compare with the current stack
      // clear note subscriptions
      for (var subscription in noteSubscriptions) {
        subscription.cancel();
      }
      noteSubscriptions = [];
      noteSubscriptions.clear();

      if (controller.isClosed) {
        return;
      }

      controller.add(stack);

      for (var note in stack.allNotes) {
        var subscription = getNoteStream(note.id!, note.ownerId).listen(
          (updatedNote) {
            if (!controller.isClosed) {
              debugPrint('Received updated note: ${updatedNote.id}');
              if (updatedNote.noteType == NoteType.template) {
                // Update the template only if the following fields are different
                if (!stack.template.compare(updatedNote)) {
                  debugPrint('Updating template');
                  stack.template = updatedNote;
                }
              } else {
                // Find and update the corresponding note in the stack
                int index = stack.overlays
                    .indexWhere((note) => note.id == updatedNote.id);
                if (index != -1) {
                  // update the note only if the following fields are different
                  if (!stack.overlays[index].compare(updatedNote)) {
                    debugPrint('Updating overlay');
                    stack.updateOverlay(index, updatedNote);
                  }
                  // check overlayedBy is not empty and overlayedBy is not in the stack
                  if (updatedNote.overlayedBy.isNotEmpty &&
                      stack.overlays
                          .where((note) =>
                              note.id == updatedNote.overlayedBy.first.noteId)
                          .isEmpty) {
                    // get the nested notes again
                    getNestedNotes(
                      noteId: noteId,
                      ownerId: ownerId,
                    ).then((stack) {
                      debugPrint('Updating nested notes');
                      handleNoteStack(stack);
                    });
                  }
                } else {
                  // Add the note to the stack
                  debugPrint('Adding new overlay');
                  stack.addOverlay(updatedNote);
                }
              }

              controller.add(stack);
            }
          },
        );

        noteSubscriptions.add(subscription);
      }
    }

    getNestedNotes(
      noteId: noteId,
      ownerId: ownerId,
    ).then((stack) {
      handleNoteStack(stack);
    });

    controller.onCancel = () {
      for (var subscription in noteSubscriptions) {
        noteSubscriptions = [];
        subscription.cancel();
        controller.close(); // Ensure to close the StreamController.
      }
    };

    return controller;
  }

  // update note's updatedAt field
  static Future<void> updateNoteUpdatedAt(String noteId, String ownerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .collection(ItemService.collectionName)
          .doc(noteId)
          .update({
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating note updatedAt: $e');
      rethrow;
    }
  }

  // get all explanations for a note
  Stream<List<ExplanationElementModel>> getExplanationsStream({
    required String noteId,
    String? ownerId,
  }) {
    try {
      var controller = StreamController<List<ExplanationElementModel>>();
      List<StreamSubscription<List<PageModel>>> subscriptions = [];

      // Get all pages
      PageService().getPages(noteId, ownerId).then((pages) {
        // Get all explanations from all pages
        var explanations = pages
            .map((page) => page.graphicElements.where(
                (element) => element.type == GraphicElementType.explanation))
            .expand((element) => element)
            .map((element) => element as ExplanationElementModel)
            .toList();

        // Sort the explanations by their title
        explanations.sort((a, b) => a.title.compareTo(b.title));

        // Yield the explanations
        controller.add(explanations);

        // Listen to pages stream
        var pagesStream = PageService().getPagesStream(
          noteId,
          ownerId,
        );

        var subscription = pagesStream.listen((pages) {
          // Get all explanations from all pages
          var explanations = pages
              .map((page) => page.graphicElements.where(
                  (element) => element.type == GraphicElementType.explanation))
              .expand((element) => element)
              .map((element) => element as ExplanationElementModel)
              .toList();

          // Sort the explanations by their title
          explanations.sort((a, b) => a.title.compareTo(b.title));

          // Yield the explanations
          controller.add(explanations);
        });

        subscriptions.add(subscription);
      });

      controller.onCancel = () {
        for (var subscription in subscriptions) {
          subscription.cancel();
        }
        subscriptions.clear();
      };

      return controller.stream;
    } catch (e) {
      debugPrint('Error getting explanations stream: $e');
      // Handle or rethrow the exception as needed
      rethrow;
    }
  }

  Future<String> createFromPdf({
    required String name,
    String? parentId,
    PdfDocument? pdfDocument,
  }) async {
    if (pdfDocument == null) {
      throw Exception('PDF document not found');
    }

    // check usage limit
    if (await isUsageLimitReached()) {
      throw Exception('Usage limit reached');
    }

    // check if name already exists
    name = await getNextName(name, ItemType.note, parentId: parentId);

    final newNote = await db
        .collection('users')
        .doc(getUserId())
        .collection(ItemService.collectionName)
        .add(NoteModel(
          ownerId: getUserId()!,
          name: name,
          parentId: parentId,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          createdBy: getUserId()!,
        ).toMap());

    // upload the pdf as images
    final pdfImages = (await uploadPdfImages(
      pdfDocument: pdfDocument,
      name: name,
      prefix: newNote.id,
    ));

    // append pages to the new note
    await Future.wait(
      List.generate(
        pdfImages.length,
        (index) async {
          await newNote.collection(PageService.pagesCollectionName).add(
                PageModel(
                  order: index,
                  backgroundImageUrl: pdfImages[index],
                ).toMap(),
              );
        },
      ),
    );

    return newNote.id;
  }

  Future<List<String>> uploadPdfImages({
    required PdfDocument pdfDocument,
    required String name,
    String? prefix,
  }) async {
    final imagesMap = <int, String>{};

    try {
      // Iterate over all pages and process them asynchronously
      await Future.wait(
        List.generate(
          pdfDocument.pagesCount,
          (index) async {
            final page = await pdfDocument.getPage(index + 1);
            try {
              final pageImage = await page.render(
                width: page.width * 4,
                height: page.height * 4,
                format: PdfPageImageFormat.png,
                backgroundColor: '#ffffff',
              );

              if (pageImage == null) {
                throw Exception('Page image not found');
              }

              final fileName = '${name}_page_${index + 1}.png';
              final url = await UploadService().uploadImageBytes(
                imageBytes: pageImage.bytes,
                fileName: fileName,
                prefix: prefix,
              );

              imagesMap[index] = url;
            } finally {
              // Always close the page after processing to free resources
              page.close();
            }
          },
        ),
      );

      // Return the list of URLs in the order of page index
      return List.generate(
        pdfDocument.pagesCount,
        (index) => imagesMap[index]!,
      );
    } finally {
      // Ensure the PdfDocument is closed after all processing is done
      pdfDocument.close();
    }
  }

  Future exportExcel(String noteId) async {
    debugPrint('Exporting excel file...');

    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // get template note
    var note = await getNote(noteId, getUserId());
    var pages = (await PageService().getPages(noteId, getUserId()))
      ..sort(
        (a, b) => a.order.compareTo(b.order),
      );

    if (note.noteType != NoteType.template) {
      debugPrint('Note is not a template');
      return;
    }

    var mcs = note.multipleChoices ?? [];
    const correctAnswerRow = 1;
    const headerRow = 2;

    debugPrint('Exporting ${mcs.length} multiple choice questions');

    // add excel headers
    // User name, User email, [MC1, MC2, MC3, ...], MC Subtotal, [Score1, Score2, Score3, ...], Score Subtotal, Total
    sheet
      ..cell(CellIndex.indexByString('A$headerRow')).value =
          TextCellValue('User name')
      ..cell(CellIndex.indexByString('B$headerRow')).value =
          TextCellValue('User email');

    var colChar = 'C';

    for (var i = 0; i < mcs.length; i++) {
      // add column headers for each multiple choice question horizontally
      var answerIndex = '$colChar$correctAnswerRow';

      final correctOptionString =
          mcs[i].correctAnswer?.toString().split('.').last ?? '';

      sheet.cell(CellIndex.indexByString(answerIndex)).value =
          TextCellValue(correctOptionString);

      var index = '$colChar$headerRow';
      sheet.cell(CellIndex.indexByString(index)).value =
          TextCellValue('MC${i + 1}');

      // increment column character
      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);
    }

    // add column headers for MC subtotal
    var index = '$colChar$headerRow';
    sheet.cell(CellIndex.indexByString(index)).value =
        TextCellValue('MC Subtotal');

    // increment column character
    colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

    // add column headers for each score question horizontally
    final templateMarkings = note.markings ?? [];
    // order by page order
    templateMarkings.sort((a, b) {
      final pageA = pages.firstWhere((element) => element.id == a.pageId);
      final pageB = pages.firstWhere((element) => element.id == b.pageId);
      return pageA.order.compareTo(pageB.order);
    });

    for (var i = 0; i < templateMarkings.length; i++) {
      final markingName = "Question ${i + 1}";
      // add column headers for each score question horizontally
      var index = '$colChar$headerRow';
      sheet.cell(CellIndex.indexByString(index)).value =
          TextCellValue(markingName);

      // increment column character
      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);
    }

    // add column headers for score subtotal
    index = '$colChar$headerRow';
    sheet.cell(CellIndex.indexByString(index)).value =
        TextCellValue('Score Subtotal');

    // increment column character
    colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

    // add column headers for total
    index = '$colChar$headerRow';
    sheet.cell(CellIndex.indexByString(index)).value = TextCellValue('Total');

    // get all responses notes
    final responseNotes = await getOverlayNotes(
      noteId: noteId,
      type: NoteType.exercise,
    );

    final userService = UserService();

    // add responses to the excel sheet
    for (var i = 0; i < responseNotes.length; i++) {
      var responseNote = responseNotes[i];

      var colChar = 'A';
      var rowIdx = i + headerRow + 1;

      // add user name and email
      final userInfo = await userService.getUser(responseNote.createdBy);

      sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
          TextCellValue(userInfo.name ?? '');

      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

      sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
          TextCellValue(userInfo.email);

      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

      // add multiple choice answers
      var mcSubtotal = 0;
      for (var j = 0; j < mcs.length; j++) {
        final mc = mcs[j];
        final response = responseNote.multipleChoices?[j];

        if (response == null) {
          continue;
        }

        final isCorrect = mc.correctAnswer == response.correctAnswer;
        final choosenOptionString =
            response.correctAnswer?.toString().split('.').last ?? '';

        if (isCorrect) {
          mcSubtotal++;
        }

        sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
            TextCellValue(choosenOptionString);

        colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);
      }

      // add MC subtotal
      sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
          DoubleCellValue(mcSubtotal as double);

      // increment column character
      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

      // find the marking note for the response note
      final markingNote = (await getOverlayNotes(
        noteId: responseNote.id!,
        type: NoteType.marking,
      ))
          .firstOrNull;

      var scoreSubtotal = 0 as double;

      // add scores
      for (var j = 0; j < templateMarkings.length; j++) {
        debugPrint('Adding score $j for response $i');
        MarkingModel? marking;
        try {
          marking = markingNote?.markings?.firstWhere(
            (element) => element.markingId == templateMarkings[j].markingId,
          );
        } catch (e) {
          marking = null;
        }

        if (marking == null) {
          colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);
          continue;
        }

        final score = marking.score;

        scoreSubtotal += score;

        sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
            DoubleCellValue(score);

        colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);
      }

      debugPrint(
          'Adding score subtotal for response $i: $scoreSubtotal at $colChar$rowIdx');

      // add score subtotal
      sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
          DoubleCellValue(scoreSubtotal);

      // increment column character
      colChar = String.fromCharCode(colChar.codeUnitAt(0) + 1);

      // add total
      sheet.cell(CellIndex.indexByString('$colChar$rowIdx')).value =
          DoubleCellValue(mcSubtotal + scoreSubtotal);
    }

    // output the file for download
    final fileBytes = excel.encode();

    if (fileBytes == null) {
      debugPrint('Error encoding excel file');
      return;
    }
    // For the web, trigger a download
    if (kIsWeb) {
      final blob = html.Blob([fileBytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'export.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Handle saving on non-web platforms (Android, iOS, etc.)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/export.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      OpenFile.open(filePath);
    }
  }
}
