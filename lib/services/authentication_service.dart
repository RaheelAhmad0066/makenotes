import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:makernote/models/usage.model.dart';
import 'package:makernote/models/user.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = true;
  StreamSubscription<User?>? _authStateSubscription;

  AuthenticationService() {
    _authStateSubscription =
        _firebaseAuth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get isLoading => _isLoading;

  Stream<User?> get userStream => _firebaseAuth.authStateChanges();

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _firebaseAuth.signOut();

    // clear preferences
    await SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
  }

  // reauthenticate user
  Future<void> reauthenticate(String password) async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    // get user credential
    final credential = EmailAuthProvider.credential(
      email: _user!.email!,
      password: password,
    );

    // reauthenticate user
    await _user!.reauthenticateWithCredential(credential);
  }

  // reauthenticate with google
  Future<void> reauthenticateWithGoogle(BuildContext context) async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      try {
        await _user!.reauthenticateWithProvider(GoogleAuthProvider());
      } catch (e) {
        debugPrint('error: $e');
        rethrow;
      }
    } else {
      await _user!.reauthenticateWithPopup(GoogleAuthProvider());
    }
  }

  // reauthenticate with apple
  Future<void> reauthenticateWithApple(BuildContext context) async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      try {
        await _user!.reauthenticateWithProvider(AppleAuthProvider());
      } catch (e) {
        debugPrint('error: $e');
        rethrow;
      }
    } else {
      await _user!.reauthenticateWithPopup(AppleAuthProvider());
    }
  }

  // on signing up, add user to users collection
  Future<void> onSignedUp(User user) async {
    // check if user already exists
    final userQuery = await db.collection('users').doc(user.uid).get();
    if (userQuery.exists) {
      return;
    }

    await db.collection('users').doc(user.uid).set(
          UserModel(
            uid: user.uid,
            name: user.displayName ?? user.email!.split('@')[0],
            email: user.email!,
            photoUrl: user.photoURL,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
            usage: UsageLimitModel(
              userId: user.uid,
              usageLimit: 100,
              // 5 GB
              mediaUsageLimit: 5 * 1024 * 1024 * 1024,
            ),
          ).toMap(),
        );
  }

  Future<void> updateDisplayName(String? displayName) async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    // update user display name in firebase auth
    await _user!.updateDisplayName(displayName);

    // only update selected fields:
    // name, updatedAt
    await db.collection('users').doc(_user!.uid).update(
      {
        'name': displayName,
        'updatedAt': Timestamp.now(),
      },
    );

    notifyListeners();
  }

  Future<void> updatePhotoURL(String? photoURL) async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    // update user photo url in firebase auth
    await _user!.updatePhotoURL(photoURL);

    // only update selected fields:
    // photoUrl, updatedAt
    await db.collection('users').doc(_user!.uid).update(
      {
        'photoUrl': photoURL,
        'updatedAt': Timestamp.now(),
      },
    );

    notifyListeners();
  }

  // reset password
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // delete user
  Future<void> deleteUser() async {
    // check if user has logged in
    if (_user == null) {
      return;
    }

    // callable function to delete user from database
    var callable = FirebaseFunctions.instanceFor(region: 'asia-east2')
        .httpsCallable('deleteUser');
    await callable.call();

    // delete user from firebase auth
    await _user!.delete();

    notifyListeners();
  }
}
