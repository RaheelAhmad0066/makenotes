import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/screens/member/account/account_location.dart';
import 'package:makernote/screens/member/document/document_location.dart';
import 'package:makernote/screens/member/join_item/join_item_location.dart';
import 'package:makernote/screens/member/overview/overview_location.dart';
import 'package:makernote/screens/member/shared/shared_location.dart';
import 'package:makernote/screens/member/trash/trash_location.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/services/notification_provider.dart';
import 'package:makernote/services/notification_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/utils/view_mode.dart';
import 'package:makernote/widgets/bottom_bar.dart';
import 'package:provider/provider.dart';

import '../../widgets/main_app_bar.dart';

class MemberScreen extends HookWidget {
  MemberScreen({super.key});

  final _routerDelegate = BeamerDelegate(
    locationBuilder: (routeInformation, _) {
      if (Routes.isActive(routeInformation, Routes.documentScreen)) {
        return DocumentsLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.trashScreen)) {
        return TrashLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.accountScreen)) {
        return AccountLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.joinItemScreen)) {
        return JoinItemLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.sharedScreen)) {
        return SharedLocation(routeInformation);
      } else if (Routes.isActive(routeInformation, Routes.overviewScreen)) {
        return OverviewLocation(routeInformation);
      } else {
        // default to documents
        return DocumentsLocation(routeInformation);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthenticationService>();
    final notificationService = useMemoized(() => NotificationService(), []);

    final userId = authService.user?.uid;

    if (userId == null) {
      // Handle case where user is not logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Makernote')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    // Create instances of providers
    final viewModeNotifier =
        useMemoized(() => ViewModeNotifier(ViewMode.grid), []);
    final notificationProvider = useMemoized(
      () => NotificationProvider(notificationService, authService),
      [authService],
    );

    // Clean up when the widget is removed
    useEffect(() {
      return () {
        viewModeNotifier.dispose();
        notificationProvider.dispose();
      };
    }, [viewModeNotifier, notificationProvider]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: viewModeNotifier),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: const MainAppBar(),
          body: Row(
            children: [
              // TODO: show folder hierarchy in side menu

              Expanded(
                child: ClipRRect(
                  child: Beamer(
                    routerDelegate: _routerDelegate,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const BottomBar(),
        ),
      ),
    );
  }
}
