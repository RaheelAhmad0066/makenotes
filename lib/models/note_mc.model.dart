import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/utils/helpers/serialization.helper.dart';

enum MCOption {
  A,
  B,
  C,
  D,
}

class NoteMCModel extends ChangeNotifier {
  NoteMCModel({
    required this.correctAnswer,
    required this.createdAt,
    required this.updatedAt,
  });

  final MCOption? correctAnswer;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  NoteMCModel copyWith({
    MCOption? correctAnswer,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return NoteMCModel(
      correctAnswer: correctAnswer ?? this.correctAnswer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'correctAnswer': correctAnswer?.index,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory NoteMCModel.fromMap(Map<String, dynamic> map) {
    var correctAnswer = map['correctAnswer'] as int?;
    return NoteMCModel(
      correctAnswer:
          correctAnswer != null ? MCOption.values[correctAnswer] : null,
      createdAt: map['createdAt'] is Map
          ? parseFirestoreTimestamp(Map<String, dynamic>.from(map['createdAt']))
          : map['createdAt'],
      updatedAt: map['updatedAt'] is Map
          ? parseFirestoreTimestamp(Map<String, dynamic>.from(map['updatedAt']))
          : map['updatedAt'],
    );
  }

  factory NoteMCModel.empty() {
    return NoteMCModel(
      correctAnswer: null,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  @override
  String toString() => 'NoteMCModel(correctAnswer: $correctAnswer)';
}
