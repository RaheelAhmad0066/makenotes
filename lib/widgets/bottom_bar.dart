import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:provider/provider.dart';

import '../utils/routes.dart';

class BottomBar extends HookWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    var routeSegments = beamerKey.currentState?.currentBeamLocation.state
        .routeInformation.uri.pathSegments;

    var activeRoute = useState(
        routeSegments!.isNotEmpty ? routeSegments.first : Routes.homeScreen);

    final isActive = useCallback((String route) {
      // remove the first '/' from the route if it exists
      if (route.startsWith('/')) {
        route = route.substring(1);
      }
      // remove the first '/' from the activeRoute if it exists
      var activeRoute0 = activeRoute.value;
      if (activeRoute0.startsWith('/')) {
        activeRoute0 = activeRoute0.substring(1);
      }
      if (activeRoute0 == route) {
        return true;
      } else {
        return false;
      }
    }, [activeRoute]);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          // home screen
          IconButton(
            icon: Icon(
                isActive(Routes.homeScreen) ? Icons.home : Icons.home_outlined),
            onPressed: () {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed(Routes.homeScreen);

              activeRoute.value = Routes.homeScreen;
            },
          ),
          // join item screen
          IconButton(
            icon: Icon(
              isActive(Routes.joinItemScreen)
                  ? Icons.co_present
                  : Icons.co_present_outlined,
            ),
            onPressed: () {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed(Routes.joinItemScreen);

              activeRoute.value = Routes.joinItemScreen;
            },
          ),
          // shared screen
          IconButton(
            icon: Icon(
              isActive(Routes.sharedScreen)
                  ? Icons.folder_shared
                  : Icons.folder_shared_outlined,
            ),
            onPressed: () {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed(Routes.sharedScreen);

              activeRoute.value = Routes.sharedScreen;
            },
          ),
          // document screen
          // IconButton(
          //   icon: Icon(
          //     isActive(Routes.documentScreen)
          //         ? Icons.folder
          //         : Icons.folder_outlined,
          //   ),
          //   onPressed: () {
          //     beamerKey.currentState?.routerDelegate
          //         .beamToNamed(Routes.documentScreen);

          //     activeRoute.value = Routes.documentScreen;
          //   },
          // ),
          // trash screen
          IconButton(
            icon: Icon(
              isActive(Routes.trashScreen)
                  ? Icons.delete
                  : Icons.delete_outline,
            ),
            onPressed: () {
              beamerKey.currentState?.routerDelegate
                  .beamToNamed(Routes.trashScreen);

              activeRoute.value = Routes.trashScreen;
            },
          ),
          // account screen
          Consumer<AuthenticationService>(
            builder: (context, authService, child) {
              return IconButton(
                icon: authService.user?.photoURL != null
                    ? CircleAvatar(
                        radius: IconTheme.of(context).size! / 2,
                        backgroundImage:
                            NetworkImage(authService.user!.photoURL!),
                      )
                    : CircleAvatar(
                        radius: IconTheme.of(context).size! / 2,
                        child: const Icon(Icons.person),
                      ),
                onPressed: () {
                  beamerKey.currentState?.routerDelegate
                      .beamToNamed(Routes.accountScreen);

                  activeRoute.value = Routes.accountScreen;
                },
              );
            },
          ),

          // test screen
          if (kDebugMode)
            IconButton(
              icon: Icon(
                isActive(Routes.testScreen)
                    ? Icons.bug_report
                    : Icons.bug_report_outlined,
              ),
              onPressed: () {
                beamerKey.currentState?.routerDelegate
                    .beamToNamed(Routes.testScreen);

                activeRoute.value = Routes.testScreen;
              },
            ),
        ],
      ),
    );
  }
}
