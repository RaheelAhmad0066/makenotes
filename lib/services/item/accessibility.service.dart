import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:makernote/models/access_token.model.dart';
import 'package:makernote/models/accessibility.model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/utils/access_right.dart';
import 'package:makernote/utils/utils.dart';

class AccessibilityService {
  static const int _expiryTime = 7 * 24 * 60 * 60; // 7 days in seconds
  static const String tokensCollectionName = 'sharedTokens';
  static const String accessibilityCollectionName = 'accessibility';
  static const String accessiblesCollectionName = 'accessibles';

  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<AccessTokenModel> createToken(
    String itemId,
    List<AccessRight> rights,
  ) async {
    if (rights.isEmpty) {
      throw Exception('Rights cannot be empty');
    }

    // check if this user has the item
    final itemQuery = await db
        .collection('users')
        .doc(currentUserId)
        .collection(ItemService.collectionName)
        .doc(itemId)
        .get();
    if (!itemQuery.exists) {
      throw Exception('Item does not exist');
    }

    // check if any token with the same rights already exists and is expiring more than 6 days later
    final query = await db
        .collection('users')
        .doc(currentUserId)
        .collection(ItemService.collectionName)
        .doc(itemId)
        .collection(tokensCollectionName)
        .where('rights',
            isEqualTo: rights.map((e) => e.toString().split('.').last).toList())
        .where('expiresAt',
            isGreaterThan:
                Timestamp.fromDate(DateTime.now().add(const Duration(days: 6))))
        .get();

    if (query.docs.isNotEmpty) {
      debugPrint('A token with the same rights already exists');
      return AccessTokenModel.fromFirestore(query.docs.first);
    }

    String? token;
    bool tokenExists = true;
    int attempts = 0;
    const maxAttempts = 5; // or any reasonable number

    while (tokenExists && attempts < maxAttempts) {
      token = Utils.createShortToken(6);

      try {
        // Check if the token already exists in any sharedTokens subcollection
        final query = await db
            .collectionGroup(tokensCollectionName)
            .where('token', isEqualTo: token)
            .get();

        tokenExists = query.docs.isNotEmpty;
      } catch (e) {
        // Log the error and rethrow or handle accordingly
        debugPrint('Error checking token: $e');
        rethrow;
      }
      attempts++;
    }

    if (tokenExists || token == null) {
      throw Exception('Unable to generate a unique token');
    }

    final tokenModel = AccessTokenModel(
      token: token,
      rights: rights,
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(
        DateTime.now().add(const Duration(seconds: _expiryTime)),
      ),
    );

    // create the token in the item subcollection `sharedTokens`
    final tokenRef = await db
        .collection('users')
        .doc(currentUserId)
        .collection(ItemService.collectionName)
        .doc(itemId)
        .collection(tokensCollectionName)
        .add(tokenModel.toFirestore());

    // update the token with the id
    return tokenModel.copyWith(id: tokenRef.id);
  }

  Future<void> deleteToken(String itemId, String tokenId) async {
    await db
        .collection('users')
        .doc(currentUserId)
        .collection(ItemService.collectionName)
        .doc(itemId)
        .collection(tokensCollectionName)
        .doc(tokenId)
        .delete();
  }

  Future<bool> validateToken(String token) async {
    final query = await db
        .collectionGroup(tokensCollectionName)
        .where('token', isEqualTo: token)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .get();

    return query.docs.isNotEmpty;
  }

  /// Applies the access rights of the token to the item
  /// Throws an exception if the token does not exist or has expired
  /// Throws an exception if the user is not logged in
  /// Throws an exception if the user already has access to the item
  /// Returns a future that completes with the corresponding item id
  Future<AccessRightApplicationResult> applyAccessRight(String token) async {
    debugPrint('Applying access right');
    if (currentUserId == null) {
      throw Exception('User is not logged in');
    }

    // Check if the token exists and has not expired
    final normalizedToken = token.toUpperCase();
    final query = await db
        .collectionGroup(tokensCollectionName)
        .where('token', isEqualTo: normalizedToken)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Token does not exist or has expired');
    }

    final tokenDoc = query.docs.first;
    final itemRef = tokenDoc.reference.parent.parent!;

    // FirebaseFunctions
    final HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
      'applyAccessRight',
    );

    try {
      await callable.call(
        <String, dynamic>{
          'token': token,
        },
      );
    } catch (e) {
      debugPrint('Error applying access right: $e');
      rethrow;
    }

    return AccessRightApplicationResult(
      item: ItemModel.fromFirestore(await itemRef.get()),
      ownerId: itemRef.parent.parent!.id,
      tokenId: tokenDoc.id,
    );
  }

  Future<void> grantAccessRight({
    required String itemId,
    required String ownerId,
    String? userId,
    List<AccessRight>? rights,
  }) async {
    if (currentUserId == null) {
      throw Exception('User is not logged in');
    }

    final HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
      'grantAccessRight',
    );

    try {
      await callable.call(
        <String, dynamic>{
          'itemId': itemId,
          'ownerId': ownerId,
          'userId': userId,
          'rights': rights?.map((e) => e.toString().split('.').last).toList(),
        },
      );

      // wait for 750ms to allow the cloud function to finish
      await Future.delayed(const Duration(milliseconds: 750));
    } catch (e) {
      debugPrint('Error granting access right: $e');
      rethrow;
    }
  }

  Future<void> removeAccessRight({
    required String itemId,
    String? userId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User is not logged in');
    }

    final HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable(
      'removeAccessRight',
    );

    try {
      await callable.call(
        <String, dynamic>{
          'itemId': itemId,
          'userId': userId,
        },
      );
    } catch (e) {
      debugPrint('Error removing access right: $e');
      rethrow;
    }
  }

  Future<bool> checkAccessRight({
    required String itemId,
    required String ownerId,
    required AccessRight right,
  }) async {
    if (currentUserId == null) {
      throw Exception('User is not logged in');
    }
    if (currentUserId == ownerId) {
      return true;
    }

    final query = await db
        .collection('users')
        .doc(ownerId)
        .collection(ItemService.collectionName)
        .doc(itemId)
        .collection(accessibilityCollectionName)
        .where('rights', arrayContains: right.toString().split('.').last)
        .get();

    if (query.docs.isEmpty) {
      return false;
    }

    final itemAccessibility = AccessibilityModel.fromFirestore(
      query.docs.first,
    );

    return itemAccessibility.rights.contains(right);
  }

  Future<List<AccessRight>> getAccessRights({
    required String itemId,
    required String ownerId,
  }) async {
    try {
      final query = await db
          .collection('users')
          .doc(ownerId)
          .collection(ItemService.collectionName)
          .doc(itemId)
          .collection(accessibilityCollectionName)
          .where('userId', isEqualTo: currentUserId)
          .get();

      if (query.docs.isEmpty) {
        return [];
      }

      final itemAccessibility = AccessibilityModel.fromFirestore(
        query.docs.first,
      );

      return itemAccessibility.rights;
    } catch (e) {
      debugPrint('Error getting access rights: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getSharingUsers({
    required String itemId,
    String? ownerId,
  }) async {
    try {
      final query = await db
          .collection('users')
          .doc(ownerId ?? currentUserId)
          .collection(ItemService.collectionName)
          .doc(itemId)
          .collection(accessibilityCollectionName)
          .get();

      if (query.docs.isEmpty) {
        return [];
      }

      final accessibilities =
          query.docs.map((e) => AccessibilityModel.fromFirestore(e)).toList();

      final userIds = accessibilities.map((e) => e.userId).toList();

      final usersQuery = await db
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return usersQuery.docs.map((e) => UserModel.fromFirestore(e)).toList();
    } catch (e) {
      debugPrint('Error getting sharing users: $e');
      rethrow;
    }
  }
}

class AccessRightApplicationResult {
  final ItemModel item;
  final String ownerId;
  final String tokenId;

  AccessRightApplicationResult({
    required this.item,
    required this.ownerId,
    required this.tokenId,
  });

  @override
  String toString() {
    return 'AccessRightApplicationResult(item: $item, ownerId: $ownerId, tokenId: $tokenId)';
  }
}
