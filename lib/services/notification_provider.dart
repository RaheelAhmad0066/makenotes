import 'package:flutter/material.dart';
import 'package:makernote/models/notification.model.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/services/notification_service.dart';
import 'package:makernote/services/user.service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  final NotificationService _notificationService;
  final AuthenticationService _authService;

  NotificationProvider(this._notificationService, this._authService) {
    if (_authService.user == null) {
      throw Exception('User is not authenticated');
    }

    _notificationService
        .userNotificationsStream(_authService.user!.uid)
        .listen((notifications) {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.isRead).length;
      notifyListeners();
    });

    debugPrint('NotificationProvider initialized');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationService.markNotificationAsRead(
        _authService.user!.uid, notificationId);
    _notifications = _notifications.map((n) {
      if (n.id == notificationId) {
        return NotificationModel(
          title: n.title,
          message: n.message,
          date: n.date,
          relatedNoteId: n.relatedNoteId,
          isRead: true,
          sender: n.sender,
          receiver: n.receiver,
        );
      }
      return n;
    }).toList();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications.where((n) => !n.isRead)) {
      if (notification.id == null) continue;
      await markNotificationAsRead(notification.id!);
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    String? relatedNoteId,
    String? receiverId,
  }) async {
    final userService = UserService();

    final sender = await userService.getUser(_authService.user!.uid);

    // TODO: Implement notification receiver
    final receiver = await userService.getUser(_authService.user!.uid);

    await _notificationService.addNotification(
      _authService.user!.uid,
      title,
      message,
      sender,
      receiver,
      relatedNoteId: relatedNoteId,
    );
  }
}
