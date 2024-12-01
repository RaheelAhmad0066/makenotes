import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:makernote/models/user.model.dart';

class UserService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<UserModel> getUser(String uid) async {
    DocumentSnapshot userSnap = await db.collection('users').doc(uid).get();

    if (userSnap.exists) {
      return UserModel.fromFirestore(userSnap);
    } else {
      throw Exception('User not found');
    }
  }
}
