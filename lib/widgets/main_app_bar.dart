import 'package:flutter/material.dart';
import 'package:makernote/widgets/logo.dart';
import 'package:makernote/widgets/notification_icon_button.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const MainAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // leading: Builder(
      //   builder: (context) => IconButton(
      //     icon: const Icon(Icons.menu),
      //     onPressed: () {
      //       // sideMenuController.current.toggle();
      //     },
      //   ),
      // ),
      title: const Row(
        children: [
          Logo(),
          Text('Makernote'),
        ],
      ),
      actions: const [
        // TODO: notifications button
        // NotificationIcon(),
      ],
    );
  }
}
