// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makernote/main.dart';

void main() {
  test('Sync manager', () async {
    final syncManager = SyncManager();

    // First sync
    final firstSync = syncManager.sync('1');
    // Second sync
    final secondSync = syncManager.sync('1');

    // Await both syncs
    final firstResult = await firstSync;
    final secondResult = await secondSync;

    // Expect the same result
    expect(firstResult, secondResult);
  });
}

class SyncManager {
  final Map<String, Future<String>> _operationCache = {};

  Future<String> sync(String id) async {
    // Check if there's an ongoing operation
    if (!_operationCache.containsKey(id)) {
      // If not, store the Future representing the ongoing operation
      _operationCache[id] = _performSync(id);
    }

    // Await the Future from the cache (either the ongoing operation or the cached result)
    return await _operationCache[id]!;
  }

  Future<String> _performSync(String id) async {
    // Perform the sync operation
    final result = await Future.delayed(
      const Duration(seconds: 2),
      () => 'Synced $id ${DateTime.now()}',
    );

    print(result);

    // Remove the Future from the cache
    _operationCache.remove(id);

    return result;
  }
}
