import 'package:flutter/material.dart';

import 'item_model.dart';

class ItemListWrapper extends ChangeNotifier {
  ItemListWrapper({
    required List<ItemModel> items,
  }) : _items = items;

  List<ItemModel> _items;

  List<ItemModel> get items => _items;

  @override
  dispose() {
    items = [];
    items.clear();
    super.dispose();
  }

  set items(List<ItemModel> value) {
    _items = value;
    notifyListeners();
  }

  void deleteItem(ItemModel item) {
    _items.remove(item);
    notifyListeners();
  }

  // Method to clear items and notify listeners
  void clearItems() {
    _items.clear();
    notifyListeners();
  }
}
