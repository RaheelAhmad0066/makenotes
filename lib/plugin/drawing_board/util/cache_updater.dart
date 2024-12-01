import 'package:makernote/plugin/drawing_board/util/debouncer.dart';

class CacheUpdater<TValue> {
  CacheUpdater({
    required this.batchUpdate,
    double maxUpdateFrequency = 0.1333,
  }) {
    _debouncer = Debouncer(
      milliseconds: (maxUpdateFrequency * 1000).toInt(),
    );
  }
  final Future<void> Function(List<TValue> items) batchUpdate;

  List<TValue> _cachedItems = <TValue>[];

  late final Debouncer _debouncer;

  Future<void> push(TValue item) async {
    _cachedItems.add(item);

    _debouncer.run(() async {
      var temp = _cachedItems.toList();
      _cachedItems.clear();
      await _batchUpdate(temp);
    });
  }

  void clear() {
    _cachedItems = [];
    _cachedItems.clear();
  }

  Future<void> _batchUpdate(List<TValue> items) async {
    await batchUpdate(items);
  }

  void dispose() {
    _cachedItems.clear();
    _debouncer.dispose();
  }
}
