import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/usage.model.dart';
import 'package:makernote/utils/helpers/serialization.helper.dart';

class UserModel extends ChangeNotifier {
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final UsageLimitModel? usage;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.usage,
  });

  @override
  void dispose() {
    // Perform any additional cleanup here if needed
    super.dispose();
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] is Map
          ? parseFirestoreTimestamp(
              Map<String, dynamic>.from(data['createdAt']))
          : data['createdAt'],
      updatedAt: data['updatedAt'] is Map
          ? parseFirestoreTimestamp(
              Map<String, dynamic>.from(data['updatedAt']))
          : data['updatedAt'],
      usage: data['usage'] != null
          ? UsageLimitModel.fromMap(Map<String, dynamic>.from(data['usage']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'usage': usage?.toMap(),
    };
  }
}
