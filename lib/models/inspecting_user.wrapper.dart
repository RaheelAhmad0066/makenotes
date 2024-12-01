import 'package:flutter/material.dart';
import 'user.model.dart';

class InspectingUserWrapper extends ChangeNotifier {
  UserModel? _user;
  String? _noteId;

  UserModel? get user => _user;

  set user(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  String? get noteId => _noteId;

  set noteId(String? noteId) {
    _noteId = noteId;
    notifyListeners();
  }

  @override
  void dispose() {
    _user?.dispose();
    _noteId = null;
    super.dispose();
  }

  void set(UserModel? user, String? noteId) {
    _user = user;
    _noteId = noteId;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _noteId = null;
    notifyListeners();
  }
}
