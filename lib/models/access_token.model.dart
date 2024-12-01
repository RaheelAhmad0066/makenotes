import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/utils/access_right.dart';

class AccessTokenModel {
  final String? id;
  final String token;
  final List<AccessRight> rights;
  final Timestamp createdAt;
  final Timestamp expiresAt;

  AccessTokenModel({
    this.id,
    required this.token,
    required this.rights,
    required this.createdAt,
    required this.expiresAt,
  });

  AccessTokenModel copyWith({
    String? id,
    String? token,
    List<AccessRight>? rights,
    Timestamp? createdAt,
    Timestamp? expiresAt,
  }) {
    return AccessTokenModel(
      id: id ?? this.id,
      token: token ?? this.token,
      rights: rights ?? this.rights,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'token': token,
      'rights': rights.map((e) => e.toString().split('.').last).toList(),
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory AccessTokenModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AccessTokenModel(
      id: doc.id,
      token: data['token'] as String,
      rights: (data['rights'] as List<dynamic>)
          .map((e) => AccessRight.values.firstWhere(
                (element) => element.toString().split('.').last == e,
              ))
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      expiresAt: data['expiresAt'] as Timestamp,
    );
  }
}
