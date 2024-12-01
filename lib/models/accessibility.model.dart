import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/utils/access_right.dart';

class AccessibilityModel {
  final String? id;
  final String userId;
  final List<AccessRight> rights;

  AccessibilityModel({
    this.id,
    required this.userId,
    required this.rights,
  });

  AccessibilityModel copyWith({
    String? id,
    String? userId,
    List<AccessRight>? rights,
  }) {
    return AccessibilityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rights: rights ?? this.rights,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'rights': rights.map((e) => e.toString().split('.').last).toList(),
    };
  }

  factory AccessibilityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AccessibilityModel(
      id: doc.id,
      userId: data['userId'] as String,
      rights: (data['rights'] as List<dynamic>)
          .map((e) => AccessRight.values.firstWhere(
                (element) => element.toString().split('.').last == e,
              ))
          .toList(),
    );
  }
}
