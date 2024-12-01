import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/models/user.model.dart';

class NotificationModel {
  final String? id;
  final String title;
  final String message;
  final DateTime date;
  final String? relatedNoteId;
  final bool isRead;
  final UserModel sender;
  final UserModel receiver;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    this.relatedNoteId,
    this.isRead = false,
    required this.sender,
    required this.receiver,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      relatedNoteId: data['relatedNoteId'],
      isRead: data['isRead'] ?? false,
      sender: UserModel.fromMap(data['receiver']),
      receiver: UserModel.fromMap(data['receiver']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'date': date,
      'relatedNoteId': relatedNoteId,
      'isRead': isRead,
      'sender': sender.toMap(),
      'receiver': receiver.toMap(),
    };
  }
}
