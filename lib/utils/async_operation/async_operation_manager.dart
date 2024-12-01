class AsyncOperationManager<T> {
  final Map<String, Future<T>> _operationCache = {};

  Future<T> performOperation(String key, Future<T> Function() operation) async {
    // Check if there's an ongoing operation
    if (!_operationCache.containsKey(key)) {
      // If not, store the Future representing the ongoing operation
      _operationCache[key] = operation();
    }

    // Await the Future from the cache (either the ongoing operation or the cached result)
    return await _operationCache[key]!;
  }

  // Optionally, a method to clear the cache for a specific key
  void clearCacheForKey(String key) {
    _operationCache.remove(key);
  }

  // Optionally, a method to clear the entire cache
  void clearAllCache() {
    _operationCache.clear();
  }
}
