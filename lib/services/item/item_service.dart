import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/models/usage.model.dart';
import 'package:pool/pool.dart';

abstract class ItemService<TItem extends ItemModel> {
  static const String trashBinName = 'trash-bin';
  final FirebaseFirestore db = FirebaseFirestore.instance;
  static String collectionName = 'item';

  String? trashBinId;
  bool loadingTrashBinId = false;

  ItemService() {
    getTrashBinId();
  }

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> setVisibility(String itemId, bool isVisible) async {
    try {
      await db
          .collection('users')
          .doc(getUserId())
          .collection(collectionName)
          .doc(itemId)
          .update({'isVisible': isVisible});
    } catch (e) {
      debugPrint("Error setting visibility: $e");
      rethrow;
    }
  }

  Future<UsageModel> getUsage() async {
    // check logged in, else throw error
    if (getUserId() == null) {
      throw Exception('User not logged in');
    }

    // get usage from cloud function
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-east2');
      final callable = functions.httpsCallable('getUsage');

      final response = await callable.call({
        'userId': getUserId(),
      });

      return UsageModel.fromMap(Map<String, dynamic>.from(response.data));
    } catch (e) {
      debugPrint("Error calling Cloud Function: $e");
      rethrow;
    }
  }

  Future<bool> isUsageLimitReached() async {
    final usage = await getUsage();
    if (usage.usageLimit == null) {
      return false;
    }
    return usage.usageLimit! > 0 && usage.usage >= usage.usageLimit!;
  }

  Future<int> isNameExists(String name, String? parentId) async {
    final siblings = await db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('name', isEqualTo: name)
        .where('parentId', isEqualTo: parentId)
        .get();
    return siblings.docs.length;
  }

  Future<String> getNextName(String name, ItemType type,
      {String? parentId}) async {
    final siblings = await getItems(parentId: parentId);

    // get all siblings that start with the same name using regex
    final RegExp regExp = RegExp(r'^' + name + r'(\s\(\d+\))?$');
    final List<String> siblingNames = siblings
        .where((element) => element.type == type)
        .map((e) => e.name)
        .where((element) => regExp.hasMatch(element))
        .toList();

    debugPrint('Siblings: $siblingNames');

    // if no siblings found, return the name
    if (siblingNames.isEmpty) {
      return name;
    }

    // Extract the digits from the sibling names and find the maximum
    final RegExp digitRegExp = RegExp(r'\d+');
    final List<int> counts = siblingNames.map((siblingName) {
      final match = digitRegExp.firstMatch(siblingName);
      return match != null ? int.parse(match.group(0)!) : 0;
    }).toList();
    final int maxCount = counts.isNotEmpty ? counts.reduce(max) : 0;

    // increment the max count and return the new name
    return '$name (${maxCount + 1})';
  }

  Future<String> addItem(String name, {String? parentId});

  Future<List<ItemModel>> searchItemsByParentId(String keyword,
      {String? parentId, int limit = 5}) async {
    Query collectionQuery = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('isTrashBin', isNotEqualTo: true);

    // If parentId is null, get root folders.
    if (parentId == null || parentId.isEmpty) {
      collectionQuery = collectionQuery.where('parentId', isNull: true);
    } else {
      collectionQuery = collectionQuery.where('parentId', isEqualTo: parentId);
    }

    QuerySnapshot snapshot = await collectionQuery.get();

    List<ItemModel> items = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['type'] == ItemType.folder.name) {
        return FolderModel.fromFirestore(doc);
      } else if (data['type'] == 'note') {
        return NoteModel.fromFirestore(doc);
      } else {
        throw Exception('Unknown item type');
      }
    }).where((element) {
      if (element is FolderModel) {
        return true;
      } else if (element is NoteModel) {
        // return template note only
        return element.noteType == NoteType.template;
      } else {
        throw Exception('Unknown item type');
      }
    }).toList();

    // set limit
    if (items.length > limit) {
      items = items.sublist(0, limit);
    }

    return items;
  }

  Future<List<ItemModel>> getParentItems(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      return Future.value([]); // Root folder, return empty list
    }

    DocumentSnapshot itemSnap = await db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .doc(itemId)
        .get();

    if (itemSnap.exists) {
      String? parentId = itemSnap.get('parentId');
      if (parentId == null || parentId.isEmpty) {
        // Parent is root folder, return self as correct type
        Map<String, dynamic>? data = itemSnap.data() as Map<String, dynamic>?;

        if (data == null) {
          throw Exception('Item data is null');
        }

        if (data['type'] == 'folder') {
          return Future.value([FolderModel.fromFirestore(itemSnap)]);
        } else if (data['type'] == 'note') {
          return Future.value([NoteModel.fromFirestore(itemSnap)]);
        } else {
          throw Exception('Unknown item type');
        }
      } else {
        // Parent is not root folder, get parent items and add self
        List<ItemModel> parentItems = await getParentItems(parentId);
        Map<String, dynamic> data = itemSnap.data() as Map<String, dynamic>;
        ItemModel item;
        if (data['type'] == 'folder') {
          item = FolderModel.fromFirestore(itemSnap);
        } else if (data['type'] == 'note') {
          item = NoteModel.fromFirestore(itemSnap);
        } else {
          throw Exception('Unknown item type');
        }
        return Future.value([
          ...parentItems,
          item,
        ]);
      }
    } else {
      return Future.value([]);
    }
  }

  Future<List<ItemModel>> getItems({
    String? parentId,
  }) async {
    Query collectionQueryForItems = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('isTrashBin', isEqualTo: false);

    if (parentId == null || parentId.isEmpty) {
      collectionQueryForItems = collectionQueryForItems.where('parentId',
          isNull: true); // Root folder, return empty list
    } else {
      collectionQueryForItems =
          collectionQueryForItems.where('parentId', isEqualTo: parentId);
    }

    QuerySnapshot snapshot = await collectionQueryForItems.get();

    List<ItemModel> items = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'folder') {
        return FolderModel.fromFirestore(doc);
      } else if (data['type'] == 'note') {
        return NoteModel.fromFirestore(doc);
      } else {
        throw Exception('Unknown item type');
      }
    }).toList();

    return items;
  }

  Stream<List<ItemModel>> getItemsStream({
    String? parentId,
    bool sortDescending = false,
  }) {
    Query collectionQueryForNotes = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('isTrashBin', isEqualTo: false)
        .where('type', isEqualTo: ItemType.note.name)
        .where('noteType', isEqualTo: NoteType.template.index);

    Query collectionQueryForFolders = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('isTrashBin', isEqualTo: false)
        .where('type', isEqualTo: ItemType.folder.name);

    // If parentId is null, get root folders.
    // If parentId is provided, get its subfolders.
    if (parentId == null || parentId.isEmpty) {
      collectionQueryForNotes = collectionQueryForNotes.where('parentId',
          isNull: true); // Root folder, return empty list
      collectionQueryForFolders = collectionQueryForFolders.where('parentId',
          isNull: true); // Root folder, return empty list
    } else {
      collectionQueryForNotes =
          collectionQueryForNotes.where('parentId', isEqualTo: parentId);
      collectionQueryForFolders =
          collectionQueryForFolders.where('parentId', isEqualTo: parentId);
    }

    // Handle stream subscriptions

    List<ItemModel> latestNotes = [];
    List<ItemModel> latestFolders = [];

    StreamController<List<ItemModel>> notesController =
        StreamController<List<ItemModel>>();
    StreamController<List<ItemModel>> foldersController =
        StreamController<List<ItemModel>>();

    StreamSubscription<QuerySnapshot> notesSubscription =
        collectionQueryForNotes.snapshots().listen((snapshot) {
      latestNotes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'folder') {
          return FolderModel.fromFirestore(doc);
        } else if (data['type'] == 'note') {
          return NoteModel.fromFirestore(doc);
        } else {
          throw Exception('Unknown item type');
        }
      }).toList();

      // Sort the folders by name ordering by sortDescending
      latestNotes.sort((a, b) {
        if (sortDescending) {
          return b.name.compareTo(a.name);
        } else {
          return a.name.compareTo(b.name);
        }
      });

      notesController.add(latestNotes);
    });

    StreamSubscription<QuerySnapshot> foldersSubscription =
        collectionQueryForFolders.snapshots().listen((snapshot) {
      latestFolders = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'folder') {
          return FolderModel.fromFirestore(doc);
        } else if (data['type'] == 'note') {
          return NoteModel.fromFirestore(doc);
        } else {
          throw Exception('Unknown item type');
        }
      }).toList();

      // Sort the folders by name ordering by sortDescending
      latestFolders.sort((a, b) {
        if (sortDescending) {
          return b.name.compareTo(a.name);
        } else {
          return a.name.compareTo(b.name);
        }
      });

      foldersController.add(latestFolders);
    });

    notesController.onCancel = () {
      notesSubscription.cancel();
    };

    foldersController.onCancel = () {
      foldersSubscription.cancel();
    };

    return StreamGroup.merge([
      notesController.stream,
      foldersController.stream,
    ]).map((event) {
      return [...latestFolders, ...latestNotes];
    });
  }

  Stream<List<ItemModel>> getTrashedItemsStream({
    bool sortDescending = false,
  }) {
    Query collectionQuery = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .where('parentId', isEqualTo: trashBinId);

    return collectionQuery.snapshots().map((snapshot) {
      List<ItemModel> items = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'folder') {
          return FolderModel.fromFirestore(doc);
        } else if (data['type'] == 'note') {
          return NoteModel.fromFirestore(doc);
        } else {
          throw Exception('Unknown item type');
        }
      }).toList();

      // Sort the folders by name ordering by sortDescending
      items.sort((a, b) {
        if (sortDescending) {
          return b.name.compareTo(a.name);
        } else {
          return a.name.compareTo(b.name);
        }
      });

      return items;
    });
  }

  Future<void> moveToTrash(String itemId) async {
    DocumentReference itemRef = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .doc(itemId);

    itemRef.get().then((doc) {
      if (doc.exists) {
        itemRef.update({
          'previousParentId': doc.get('parentId'),
          'parentId': trashBinId,
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }

  Future<void> deleteItem({required String itemId, String? ownerId}) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-east2');
      final callable = functions.httpsCallable('deleteItemWithSubcollections');

      await callable.call({
        'userId': ownerId ?? getUserId(),
        'itemId': itemId,
      });
    } catch (e) {
      debugPrint("Error calling Cloud Function: $e");
      rethrow;
    }
  }

  Future<void> moveItem(String itemId, String? newParentId) async {
    // get current parentId
    DocumentSnapshot itemSnap = await db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .doc(itemId)
        .get();
    final String? previousParentId = itemSnap.get('parentId');

    await db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .doc(itemId)
        .update({
      'parentId': (newParentId?.isNotEmpty ?? false) ? newParentId : null,
      'previousParentId': previousParentId,
      'updatedAt': Timestamp.now(),
    });
  }

  void recoverFromTrash(String itemId) {
    DocumentReference folderRef = db
        .collection('users')
        .doc(getUserId())
        .collection(collectionName)
        .doc(itemId);

    folderRef.get().then((doc) {
      if (doc.exists) {
        // check if the previous parent folder exists
        DocumentReference parentFolderRef = db
            .collection('users')
            .doc(getUserId())
            .collection(collectionName)
            .doc(doc.get('previousParentId'));

        parentFolderRef.get().then((parentDoc) {
          if (parentDoc.exists && parentDoc.get('parentId') != trashBinId) {
            folderRef.update({
              'parentId': doc.get('previousParentId'),
              'updatedAt': Timestamp.now(),
            });
          } else {
            // parent folder does not exist, move to root folder
            folderRef.update({
              'parentId': null,
              'updatedAt': Timestamp.now(),
            });
          }
        });
      }
    });
  }

  Future<void> renameItem(String itemId, String name) async {
    try {
      await db
          .collection('users')
          .doc(getUserId())
          .collection(collectionName)
          .doc(itemId)
          .update({'name': name, 'updatedAt': Timestamp.now()});
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      if (kDebugMode) {
        print("Failed with error '${e.code}': ${e.message}");
      }
      rethrow;
    }
  }

  final Pool _firestorePool = Pool(1);

  Future<String> getTrashBinId() async {
    return _firestorePool.withResource(() async {
      if (trashBinId != null) {
        return trashBinId!;
      }

      // get the trash bin
      final trashBinRef = await db
          .collection('users')
          .doc(getUserId())
          .collection(collectionName)
          .where('name', isEqualTo: trashBinName)
          .where('parentId', isNull: true)
          .where('isTrashBin', isEqualTo: true)
          .limit(1)
          .get();

      if (trashBinRef.docs.isEmpty) {
        // trash bin does not exist, create it
        await db
            .collection('users')
            .doc(getUserId())
            .collection(collectionName)
            .add(FolderModel(
              ownerId: getUserId()!,
              name: trashBinName,
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
              isTrashBin: true,
            ).toMap());

        // get the trash bin
        final trashBinRef = await db
            .collection('users')
            .doc(getUserId())
            .collection(collectionName)
            .where('name', isEqualTo: trashBinName)
            .where('parentId', isNull: true)
            .where('isTrashBin', isEqualTo: true)
            .limit(1)
            .get();

        trashBinId = trashBinRef.docs.first.id;
        return trashBinId!;
      } else {
        trashBinId = trashBinRef.docs.first.id;
        return trashBinId!;
      }
    });
  }

  // copy item, currently only supports copying notes
  Future<void> copyItem(String itemId) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-east2');
      final callable = functions.httpsCallable('copyTemplateNote');

      await callable.call({
        'templateId': itemId,
      });
    } catch (e) {
      debugPrint("Error calling Cloud Function: $e");
      rethrow;
    }
  }
}
