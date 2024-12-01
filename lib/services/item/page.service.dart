import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/models/scribble_element_model.dart';
import 'package:makernote/plugin/drawing_board/services/i_page_service.interface.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/note_service.dart';

class PageService implements IPageService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  static const pagesCollectionName = 'pages';

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<int> getPageCount(String noteId, String? ownerId) async {
    try {
      final pagesRef = db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName);

      final querySnapshot = await pagesRef.get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint("Error getting page count: $e");
      rethrow;
    }
  }

  @override
  Future<List<PageModel>> getPages(String noteId, String? ownerId) async {
    try {
      final pagesRef = db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName);

      final querySnapshot = await pagesRef.orderBy('order').get();

      return querySnapshot.docs.map((doc) {
        debugPrint('Document data: ${doc.data()}');
        return PageModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint("Error getting pages: $e");
      rethrow;
    }
  }

  Stream<PageModel> getPageStream(String noteId, int index, String? ownerId) {
    try {
      final pageRef = db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName)
          .where('order', isEqualTo: index)
          .limit(1);

      return pageRef.snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return PageModel.fromFirestore(snapshot.docs.first);
        } else {
          // Handle the case where no page is found
          throw Exception('Page not found on index $index');
        }
      });
    } catch (e) {
      debugPrint("Error getting page stream: $e");
      rethrow;
    }
  }

  @override
  Stream<List<PageModel>> getPagesStream(String noteId, String? ownerId) {
    final pagesRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId)
        .collection(pagesCollectionName);

    final query = pagesRef.orderBy('order');

    return query.snapshots().asyncMap((snapshot) async {
      final pages = snapshot.docs
          .map((doc) => PageModel.fromFirestore(doc))
          .toList(growable: false);

      return pages;
    });
  }

  // append page
  @override
  Future<PageModel> appendPage({
    required String noteId,
    PageModel? page,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pagesCollection = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName);

      // Get the last page
      final query =
          await pagesCollection.orderBy('order', descending: true).get();

      var order = 0;
      if (query.docs.isNotEmpty) {
        // Get the order of the last page
        final lastPage = query.docs.first;
        final lastPageModel = PageModel.fromFirestore(lastPage);
        final lastPageOrder = lastPageModel.order;
        order = lastPageOrder + 1;
      }

      // Add the new page
      final newPage = await pagesCollection.add(
        page != null
            ? page
                .copyWith(
                  order: order,
                )
                .toMap()
            : PageModel(
                order: order,
              ).toMap(),
      );

      // Update the note's updatedAt field
      await NoteService.updateNoteUpdatedAt(noteId, ownerId ?? getUserId()!);

      // Fetch the new page
      final newPageSnapshot = await newPage.get();

      return PageModel.fromFirestore(newPageSnapshot);
    } catch (e) {
      if (kDebugMode) {
        print("Error appending page: $e");
      }
      rethrow;
    }
  }

  // insert page
  @override
  Future<PageModel> insertPage({
    required String noteId,
    required int position,
    PageModel? page,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pagesCollection = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName);

      // validate position
      final totalPages = (await pagesCollection.get()).docs.length;
      if (position < 0 || position > totalPages) {
        throw Exception('Invalid position');
      }

      // Check if a page with the same `referenceId` already exists
      if (page?.referenceId != null) {
        final query = await pagesCollection
            .where('referenceId', isEqualTo: page!.referenceId)
            .get();

        if (query.docs.isNotEmpty) {
          throw Exception('Page with the same reference already exists');
        }
      }

      // Start a batch
      final batch = db.batch();

      // Fetch all pages with an order greater than or equal to the position
      final query = await pagesCollection
          .where('order', isGreaterThanOrEqualTo: position)
          .get();

      // Update the order of each page by 1
      for (var doc in query.docs) {
        final page = PageModel.fromFirestore(doc);
        batch.update(doc.reference, {'order': page.order + 1});
      }

      // Add the new page
      batch.set(
        pagesCollection.doc(),
        page != null
            ? page
                .copyWith(
                  order: position,
                )
                .toMap()
            : PageModel(
                order: position,
              ).toMap(),
      );

      // Commit the batch
      await batch.commit();

      // Update the note's updatedAt field
      await NoteService.updateNoteUpdatedAt(noteId, ownerId ?? getUserId()!);

      // Fetch the new page
      final newPageSnapshot = await pagesCollection
          .where('order', isEqualTo: position)
          .get()
          .then((value) => value.docs.first);

      return PageModel.fromFirestore(newPageSnapshot);
    } catch (e) {
      if (kDebugMode) {
        print("Error inserting page: $e");
      }
      rethrow;
    }
  }

  // update page
  @override
  Future<void> updatePage({
    required String noteId,
    required PageModel page,
    String? ownerId,
  }) async {
    final pageRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId)
        .collection(pagesCollectionName)
        .doc(page.id);

    try {
      await db.runTransaction((transaction) async {
        // fetch the current state of the page
        final snapshot = await transaction.get(pageRef);

        if (!snapshot.exists) {
          throw Exception('Page does not exist!');
        }

        debugPrint('Updating page: ${page.id}\n'
            '\tElements: ${page.graphicElements.length}\n');
        // update the page
        transaction.update(pageRef, page.toMap());
      });

      // Update the page's updatedAt field
      await updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);
    } catch (e) {
      debugPrint("Error updating page: $e");
      rethrow;
    }
  }

  // delete page
  @override
  Future<void> deletePage({
    required String noteId,
    required String pageId,
    String? ownerId,
  }) async {
    try {
      final pagesCollection = db
          .collection('users')
          .doc(ownerId ?? getUserId())
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName);

      // cancel if only one page
      final query = await pagesCollection.get();
      if (query.docs.length == 1) {
        throw Exception('Cannot delete the only page');
      }

      final page =
          PageModel.fromFirestore(await pagesCollection.doc(pageId).get());

      // Start a batch
      final batch = db.batch();

      // Fetch all pages with an order greater than the page order
      final queryGreaterPages =
          await pagesCollection.where('order', isGreaterThan: page.order).get();

      // Update the order of each page by -1
      for (var doc in queryGreaterPages.docs) {
        final page = PageModel.fromFirestore(doc);
        batch.update(doc.reference, {'order': page.order - 1});
      }

      // Delete the page
      batch.delete(pagesCollection.doc(pageId));

      // Commit the batch
      await batch.commit();

      // Update the note's updatedAt field
      await NoteService.updateNoteUpdatedAt(noteId, ownerId ?? getUserId()!);
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting page: $e");
      }
      rethrow;
    }
  }

  // update page sketch
  @override
  Future<void> updatePageSketch({
    required String noteId,
    required String pageId,
    required ScribbleElementModel sketch,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName)
          .doc(pageId);

      // Update the sketch in Firestore
      await pageDoc.update({'sketch': sketch.toMap()});

      // Update the page's updatedAt field
      await updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Updated page sketch');
    } catch (e) {
      debugPrint("Error updating page sketch: $e");
      rethrow;
    }
  }

  // update page pencil kit
  @override
  Future<void> updatePagePencilKit({
    required String noteId,
    required String pageId,
    required String? data,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName)
          .doc(pageId);

      // Update the sketch in Firestore
      await pageDoc.update({'pencilKit.data': data});

      // Update the page's updatedAt field
      await updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Updated page pencil kit');
    } catch (e) {
      debugPrint("Error updating page pencil kit: $e");
      rethrow;
    }
  }

  // update page flutter drawing board
  @override
  Future<void> updatePageFlutterDrawingBoard(
      {required String noteId,
      required String pageId,
      required List<Map<String, dynamic>> data,
      String? ownerId}) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName)
          .doc(pageId);

      // Update the sketch in Firestore
      await pageDoc.update({'flutterDrawingBoard.data': data});

      // Update the page's updatedAt field
      await updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Updated page pencil kit');
    } catch (e) {
      debugPrint("Error updating page pencil kit: $e");
      rethrow;
    }
  }

  // clear page sketch
  @override
  Future<void> clearPageSketch({
    required String noteId,
    required String pageId,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(pagesCollectionName)
          .doc(pageId);

      // Update the sketch in Firestore
      await pageDoc.update({'sketch': ScribbleElementModel.empty().toMap()});

      // Update the page's updatedAt field
      await updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Cleared page sketch');
    } catch (e) {
      debugPrint("Error clearing page sketch: $e");
      rethrow;
    }
  }

  // static function update page updatedAt field
  static Future<void> updatePageUpdatedAt(
    String noteId,
    String ownerId,
  ) async {
    try {
      // update note updatedAt
      await NoteService.updateNoteUpdatedAt(noteId, ownerId);
    } catch (e) {
      debugPrint('Error updating page updatedAt: $e');
      rethrow;
    }
  }
}
