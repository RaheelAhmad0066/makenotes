import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/models/item_model.dart';

/// Folder model
///
class FolderModel extends ItemModel {
  FolderModel({
    super.id,
    required super.ownerId,
    required super.name,
    super.parentId,
    super.previousParentId,
    required super.createdAt,
    required super.updatedAt,
    super.isTrashBin = false,
    super.isVisible = true,
  }) : super(
          type: ItemType.folder,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
    };
  }

  static FolderModel fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document does not exist');
    }
    data['id'] = doc.id;
    return FolderModel.fromMap(data);
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    ItemModel item = ItemModel.fromMap(map);
    return FolderModel(
      id: item.id,
      ownerId: item.ownerId,
      name: item.name,
      parentId: item.parentId,
      previousParentId: item.previousParentId,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      isVisible: item.isVisible,
    );
  }
}
