import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/models/folder_model.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/services/item/item_service.dart';

class FolderService extends ItemService<FolderModel> {
  FolderService() : super();

  @override
  Future<String> addItem(String name, {String? parentId}) async {
    // check usage limit
    if (await isUsageLimitReached()) {
      throw Exception('Usage limit reached');
    }

    // get the next name to avoid duplicates
    name = await getNextName(name, ItemType.folder, parentId: parentId);

    var newItem = await db
        .collection('users')
        .doc(getUserId())
        .collection(ItemService.collectionName)
        .add(FolderModel(
          ownerId: getUserId()!,
          name: name,
          parentId: parentId,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ).toMap());

    return newItem.id;
  }

  void clearData() {
    // Add any necessary cleanup logic here
    // For example, resetting local caches, lists, or temporary states
  }
}
