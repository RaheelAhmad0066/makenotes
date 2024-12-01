import 'package:flutter/material.dart';
import 'package:makernote/services/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Test to add notification
              ElevatedButton(
                onPressed: () {
                  notificationProvider.addNotification(
                    title: 'Test Notification',
                    message: 'This is a test notification',
                  );
                },
                child: const Text('Add Notification'),
              ),

              Expanded(
                child: (notificationProvider.notifications.isEmpty)
                    ? const Center(child: Text('No notifications'))
                    : ListView.builder(
                        cacheExtent: 0.0,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return ListTile(
                            title: Text(notification.title),
                            subtitle: Text(notification.message),
                            leading: const Icon(Icons.notifications),
                            onTap: () async {
                              await notificationProvider
                                  .markNotificationAsRead(notification.id!);
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(notification.title),
                                    content: Text(notification.message),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
