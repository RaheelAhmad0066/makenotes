import 'package:cloud_firestore/cloud_firestore.dart';

Timestamp parseFirestoreTimestamp(Map<String, dynamic> timestampMap) {
  if (timestampMap.containsKey('_seconds') &&
      timestampMap.containsKey('_nanoseconds')) {
    return Timestamp(timestampMap['_seconds'], timestampMap['_nanoseconds']);
  } else {
    throw Exception('Invalid timestamp data');
  }
}
