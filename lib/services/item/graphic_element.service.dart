import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/services/i_graphic_element_service.interface.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/page.service.dart';

class GraphicElementService implements IGrahpicElementService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // append graphic element
  @override
  Future<void> appendGraphicElement({
    required String noteId,
    required String pageId,
    required GraphicElementModel element,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pagesCollection = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(PageService.pagesCollectionName);

      // Add the new graphic element
      await pagesCollection.doc(pageId).update({
        'graphicElements': FieldValue.arrayUnion([
          element.toMap(),
        ])
      });

      // Update the page's updatedAt field
      await PageService.updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Appended graphic element');
    } catch (e) {
      debugPrint("Error appending graphic element: $e");
      rethrow;
    }
  }

  // insert graphic element
  @override
  Future<void> insertGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    required GraphicElementModel element,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(PageService.pagesCollectionName)
          .doc(pageId);

      // Fetch the current graphic elements
      final pageSnapshot = await pageDoc.get();
      final List<dynamic> currentElements =
          pageSnapshot.data()?['graphicElements'] ?? [];

      // Convert them to GraphicElementModel
      final elements = currentElements
          .map((e) => GraphicElementModel.fromType(
                GraphicElementType.values[e['type']],
                e,
              ))
          .toList();

      // Check if the index is invalid
      if (index < 0 || index > elements.length) {
        throw Exception('Invalid index');
      }

      // Insert the new element at the given index
      if (index >= 0 && index <= elements.length) {
        elements.insert(index, element);
      }

      // Update the graphic elements in Firestore
      await pageDoc
          .update({'graphicElements': elements.map((e) => e.toMap()).toList()});

      // Update the page's updatedAt field
      await PageService.updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Inserted graphic element');
    } catch (e) {
      debugPrint("Error inserting graphic element: $e");
      rethrow;
    }
  }

  // update graphic element
  @override
  Future<void> updateGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    required GraphicElementModel element,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(PageService.pagesCollectionName)
          .doc(pageId);

      // Fetch the current graphic elements
      final pageSnapshot = await pageDoc.get();
      final List<dynamic> currentElements =
          pageSnapshot.data()?['graphicElements'] ?? [];

      // Convert them to GraphicElementModel
      final elements = currentElements
          .map((e) => GraphicElementModel.fromType(
                GraphicElementType.values[e['type']],
                e,
              ))
          .toList();

      // Check if the index is invalid
      if (index < 0 || index >= elements.length) {
        throw Exception('Invalid index');
      }

      // Find the index of the element to update
      if (index >= 0 && index < elements.length) {
        elements[index] = element; // Update the element
      }

      // Update the graphic elements in Firestore
      await pageDoc
          .update({'graphicElements': elements.map((e) => e.toMap()).toList()});

      // Update the page's updatedAt field
      await PageService.updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Updated graphic element');
    } catch (e) {
      debugPrint("Error updating graphic element: $e");
      rethrow;
    }
  }

  // batch update graphic elements
  @override
  Future<void> batchUpdateGraphicElements({
    required String noteId,
    required String pageId,
    required Map<int, GraphicElementModel> elements,
    String? ownerId,
  }) async {
    try {
      if (elements.isEmpty) {
        return;
      }
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(PageService.pagesCollectionName)
          .doc(pageId);

      // Fetch the current graphic elements
      final pageSnapshot = await pageDoc.get();
      final List<dynamic> currentElements =
          pageSnapshot.data()?['graphicElements'] ?? [];

      // Convert them to GraphicElementModel
      final currentElementsList = currentElements
          .map((e) => GraphicElementModel.fromType(
                GraphicElementType.values[e['type']],
                e,
              ))
          .toList();

      // Update the elements
      for (var index in elements.keys) {
        // Check if the index is invalid
        if (index < 0 || index >= currentElementsList.length) {
          throw Exception('Invalid index');
        }

        // Find the index of the element to update
        if (index >= 0 && index < currentElementsList.length) {
          currentElementsList[index] = elements[index]!; // Update the element
        }
      }

      // Update the graphic elements in Firestore
      await pageDoc.update({
        'graphicElements': currentElementsList.map((e) => e.toMap()).toList()
      });

      // Update the page's updatedAt field
      await PageService.updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Batch updated graphic elements');
    } catch (e) {
      debugPrint("Error batch updating graphic elements: $e");
      rethrow;
    }
  }

  // delete graphic element
  @override
  Future<void> deleteGraphicElement({
    required String noteId,
    required String pageId,
    required int index,
    String? ownerId,
  }) async {
    try {
      final userCollection = db.collection('users').doc(ownerId ?? getUserId());
      final pageDoc = userCollection
          .collection(ItemService.collectionName)
          .doc(noteId)
          .collection(PageService.pagesCollectionName)
          .doc(pageId);

      // Fetch the current graphic elements
      final pageSnapshot = await pageDoc.get();
      final List<dynamic> currentElements =
          pageSnapshot.data()?['graphicElements'] ?? [];

      // Convert them to GraphicElementModel
      final elements = currentElements
          .map((e) => GraphicElementModel.fromType(
                GraphicElementType.values[e['type']],
                e,
              ))
          .toList();

      // Check if the index is invalid
      if (index < 0 || index >= elements.length) {
        throw Exception('Invalid index');
      }

      // Remove the element with the given id
      if (index >= 0 && index < elements.length) {
        elements.removeAt(index);
      }

      // Update the graphic elements in Firestore
      await pageDoc
          .update({'graphicElements': elements.map((e) => e.toMap()).toList()});

      // Update the page's updatedAt field
      await PageService.updatePageUpdatedAt(noteId, ownerId ?? getUserId()!);

      debugPrint('Deleted graphic element');
    } catch (e) {
      debugPrint("Error deleting graphic element: $e");
      rethrow;
    }
  }
}
