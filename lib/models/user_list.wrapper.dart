import 'package:flutter/material.dart';

import 'user.model.dart';

class UserListWrapper extends ChangeNotifier {
  UserListWrapper({
    required List<UserModel> users,
  }) : _users = users;

  List<UserModel> _users;

  List<UserModel> get users => _users;

  @override
  void dispose() {
    users = [];
    users.clear();
    super.dispose();
  }

  set users(List<UserModel> value) {
    _users = value;
    notifyListeners();
  }

  void deleteUser(UserModel user) {
    _users.remove(user);
    notifyListeners();
  }
}
