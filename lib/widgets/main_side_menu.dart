import 'package:beamer/beamer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:provider/provider.dart';

class MainSideMenu extends StatefulWidget {
  const MainSideMenu({
    super.key,
    required this.beamer,
    this.controller,
    this.activeUri,
  });
  final GlobalKey<BeamerState> beamer;
  final SideMenuController? controller;
  final String? activeUri;

  @override
  State<MainSideMenu> createState() => _MainSideMenuState();
}

class _MainSideMenuState extends State<MainSideMenu> {
  final _navItems = const [
    NavItemModel(
        name: 'Join note', icon: Icons.co_present, uri: Routes.joinItemScreen),
    NavItemModel(
        name: 'Document', icon: Icons.folder, uri: Routes.documentScreen),
  ];
  final _otherItems = const [
    NavItemModel(
        name: 'Trash Bin', icon: Icons.delete, uri: Routes.trashScreen),
  ];

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      widget.beamer.currentState?.routerDelegate.beamToNamed(Routes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    return SideMenu(
      controller: widget.controller,
      mode: SideMenuMode.open,
      backgroundColor: Theme.of(context).cardColor,
      hasResizer: false,
      hasResizerToggle: false,
      builder: (data) => SideMenuData(
        items: [
          ..._navItems
              .map(
                (e) => SideMenuItemDataTile(
                  isSelected: e.uri?.contains('${widget.activeUri}') ?? false,
                  onTap: () {
                    if (e.uri == null) return;
                    widget.beamer.currentState?.routerDelegate
                        .beamToNamed(e.uri!);
                  },
                  title: e.name,
                  icon: Icon(
                    e.icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              )
              .toList(),
          const SideMenuItemDataDivider(divider: Divider()),
          const SideMenuItemDataTitle(title: 'Other'),
          ..._otherItems
              .map(
                (e) => SideMenuItemDataTile(
                  isSelected: false,
                  onTap: () {
                    if (e.uri == null) return;
                    widget.beamer.currentState?.routerDelegate
                        .beamToNamed(e.uri!);
                  },
                  title: e.name,
                  icon: Icon(
                    e.icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              )
              .toList(),
        ],
        footer: Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            direction: Axis.vertical,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton(
                  tooltip: 'Account',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            // image from url
                            authService.user?.photoURL != null
                                ? NetworkImage(authService.user!.photoURL!)
                                :
                                // image from assets
                                const AssetImage(
                                        'assets/images/default_avatar.jpg')
                                    as ImageProvider,
                      ),
                      if (data.isOpen)
                        Text(
                          authService.user?.displayName ?? '--',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        )
                    ],
                  ),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: 'account',
                        onTap: () {
                          widget.beamer.currentState?.routerDelegate
                              .beamToNamed(Routes.accountScreen);
                        },
                        child: const Text('Account'),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        onTap: () => logout(),
                        child: const Text('Logout'),
                      ),
                    ];
                  },
                  onSelected: (value) {}),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Widget {
  // ignore: unused_element
  Widget? showOrNull(bool isShow) => isShow ? this : null;
}

class NavItemModel {
  const NavItemModel({
    required this.name,
    required this.icon,
    this.uri,
  });

  final String name;
  final IconData icon;
  final String? uri;
}
