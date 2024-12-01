import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/utils/helpers/serialization.helper.dart';

import 'folder_model.dart';

enum ItemType { folder, note }

class ItemModel extends ChangeNotifier {
  final String? id;
  final String ownerId;
  final String name;
  final ItemType type; // 'folder' or 'note'
  final String? parentId;
  final String? previousParentId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isTrashBin;
  final bool isVisible;

  ItemModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.parentId,
    this.previousParentId,
    required this.createdAt,
    required this.updatedAt,
    this.isTrashBin = false,
    this.isVisible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ownerId': ownerId,
      'name': name,
      'type': type.toString().split('.').last,
      'parentId': parentId,
      if (previousParentId != null) 'previousParentId': previousParentId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isTrashBin': isTrashBin,
      'isVisible': isVisible,
    };
  }

  static ItemModel fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document does not exist');
    }
    data['id'] = doc.id;
    return ItemModel.fromMap(data);
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      ownerId: map['ownerId'],
      name: map['name'],
      type: map['type'] == 'folder' ? ItemType.folder : ItemType.note,
      parentId: map['parentId'],
      previousParentId: map['previousParentId'],
      createdAt: map['createdAt'] is Map
          ? parseFirestoreTimestamp(Map<String, dynamic>.from(map['createdAt']))
          : map['createdAt'],
      updatedAt: map['updatedAt'] is Map
          ? parseFirestoreTimestamp(Map<String, dynamic>.from(map['updatedAt']))
          : map['updatedAt'],
      isTrashBin: map['isTrashBin'] ?? false,
      isVisible: map['isVisible'] ?? true,
    );
  }

  factory ItemModel.autoType(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ItemModel.autoTypeFromMap(data);
  }
  factory ItemModel.autoTypeFromMap(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'folder':
        return FolderModel.fromMap(data);
      case 'note':
        return NoteModel.fromMap(data);
      default:
        throw Exception('Unknown item type');
    }
  }
}
