import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/accessible.model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/services/item/item_service.dart';

class SharedService extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<List<AccessibleModel>> getAllAccessibles({String? ownerId}) {
    if (ownerId == null) {
      // get all items shared with the user
      return db
          .collection('users')
          .doc(getUserId())
          .collection(AccessibilityService.accessiblesCollectionName)
          .get()
          .then((value) =>
              value.docs.map((e) => AccessibleModel.fromFirestore(e)).toList());
    }
    return db
        .collection('users')
        .doc(getUserId())
        .collection(AccessibilityService.accessiblesCollectionName)
        .where('ownerId', isEqualTo: ownerId)
        .get()
        .then((value) =>
            value.docs.map((e) => AccessibleModel.fromFirestore(e)).toList());
  }

  // get all items from accessibles collection by [ownerId] and [itemId]
  Future<List<TItem>> getAccessibleItems<TItem extends ItemModel>({
    int limit = 10,
    int offset = 0,
  }) async {
    final accessibles = await getAllAccessibles();
    List<TItem> items = [];
    for (var i = offset; i < min(offset + limit, accessibles.length); i++) {
      final accessible = accessibles[i];
      final itemSnapshot = await db
          .collection('users')
          .doc(accessible.ownerId)
          .collection(ItemService.collectionName)
          .doc(accessible.itemId)
          .get();

      if (itemSnapshot.exists) {
        items.add(ItemModel.autoType(itemSnapshot) as TItem);
      }
    }

    return items;
  }

  // get owner info by [ownerId]
  Future<UserModel> getOwnerInfo(String ownerId) async {
    final ownerSnapshot = await db.collection('users').doc(ownerId).get();
    return UserModel.fromFirestore(ownerSnapshot);
  }

  // get all owners from accessibles collection
  Future<List<UserModel>> getAccessibleOwners({
    String? keyword,
  }) async {
    final accessibles = await getAllAccessibles();

    // get distinct ownerIds
    final ownerIds = accessibles.map((e) => e.ownerId).toSet().toList();

    // get all owners from user collection
    try {
      if (ownerIds.isEmpty) {
        return [];
      }
      final owners = await db
          .collection('users')
          .where(FieldPath.documentId, whereIn: ownerIds)
          .get();

      // filter owners by keyword
      if (keyword != null && keyword.isNotEmpty == true) {
        return owners.docs.map((e) => UserModel.fromFirestore(e)).where(
          (element) {
            return element.name
                        ?.toLowerCase()
                        .contains(keyword.toLowerCase()) ==
                    true ||
                element.email.toLowerCase().contains(keyword.toLowerCase());
          },
        ).toList()
          ..sort((a, b) => a.name!.compareTo(b.name!));
      }

      return owners.docs.map((e) => UserModel.fromFirestore(e)).toList()
        ..sort((a, b) => a.name!.compareTo(b.name!));
    } catch (e) {
      debugPrint('Error getting owners: $e');
      rethrow;
    }
  }

  // get all items shared by [ownerId]
  Future<List<TItem>> getSharedItems<TItem extends ItemModel>({
    required String ownerId,
    String? parentId,
  }) async {
    try {
      // get all items shared by [ownerId] and [parentItemId] from firebase function

      final callable =
          FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
        'getItems',
      );

      final result = await callable.call<List<dynamic>>({
        'ownerId': ownerId,
        'parentId': parentId,
      });

      final mapped = result.data.map((e) {
        return ItemModel.autoTypeFromMap(Map<String, dynamic>.from(e)) as TItem;
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return mapped;
    } catch (e) {
      debugPrint('Error getting shared items: $e');
      rethrow;
    }
  }
}
