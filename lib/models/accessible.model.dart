import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/utils/access_right.dart';

class AccessibleModel {
  final String? id;
  final List<AccessRight> rights;
  final String ownerId;
  final String itemId;

  AccessibleModel({
    this.id,
    required this.rights,
    required this.ownerId,
    required this.itemId,
  });

  AccessibleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        rights = (doc.data()!['rights'] as List<dynamic>)
            .map((e) => AccessRight.values.firstWhere(
                  (element) => element.toString().split('.').last == e,
                ))
            .toList(),
        ownerId = doc.data()!['ownerId'],
        itemId = doc.data()!['itemId'];

  Map<String, dynamic> toFirestore() {
    return {
      'rights': rights.map((e) => e.toString().split('.').last).toList(),
      'ownerId': ownerId,
      'itemId': itemId,
    };
  }
}
