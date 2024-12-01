import 'package:flutter/material.dart';
import 'package:makernote/services/notification_provider.dart';
import 'package:makernote/widgets/notification_list.dart';
import 'package:provider/provider.dart';

Future<void> showNotificationDialog({required BuildContext context}) {
  final notificationProvider = context.read<NotificationProvider>();

  return showModalBottomSheet(
    context: context,
    builder: (context) => ChangeNotifierProvider.value(
      value: notificationProvider,
      child: const NotificationList(),
    ),
  );
}
