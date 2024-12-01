import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/notification.model.dart';
import 'package:makernote/models/user.model.dart';

class NotificationService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<NotificationModel>> getUserNotifications(String uid) async {
    QuerySnapshot notificationSnap = await db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

    return notificationSnap.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  // Notification stream
  Stream<List<NotificationModel>> userNotificationsStream(String uid) {
    debugPrint('Notification stream initialized');
    return db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList())
        .handleError((error) {
      debugPrint('Error occurred: $error');
    });
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> addNotification(
    String uid,
    String title,
    String message,
    UserModel sender,
    UserModel receiver, {
    String? relatedNoteId,
  }) async {
    NotificationModel notification = NotificationModel(
      title: title,
      message: message,
      date: DateTime.now(),
      isRead: false,
      relatedNoteId: relatedNoteId,
      sender: sender,
      receiver: receiver,
    );
    await db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(notification.toMap());
  }
}
