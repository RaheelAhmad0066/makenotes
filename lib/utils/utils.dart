import 'dart:convert';
import 'dart:math';

class Utils {
  static final Random _random = Random.secure();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a random string of [length] characters encoded in base64.
  static String createCryptoRandomString([int length = 32]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Generates a aphanumeric string of [length] characters.
  static String createShortToken([int length = 6]) {
    return List.generate(
        length, (index) => _chars[_random.nextInt(_chars.length)]).join();
  }
}
