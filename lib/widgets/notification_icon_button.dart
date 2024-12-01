import 'package:flutter/material.dart';
import 'package:makernote/services/notification_provider.dart';
import 'package:makernote/utils/helpers/notification.helper.dart';
import 'package:provider/provider.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () async {
            await showNotificationDialog(context: context);
            if (context.mounted) {
              await context.read<NotificationProvider>().markAllAsRead();
            }
          },
        ),
        Positioned(
          right: 0,
          child: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return provider.unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${provider.unreadCount > 99 ? '99+' : provider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
