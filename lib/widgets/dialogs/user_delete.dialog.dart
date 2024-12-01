import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/utils/helpers/user.helper.dart';
import 'package:provider/provider.dart';

class UserDeleteDialog extends HookWidget {
  const UserDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Account"),
      content: const Text("Are you sure you want to delete your account?"),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).hintColor,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            await showReauthenticateDialog(
              context: context,
              onSuccess: () async {
                final authService =
                    Provider.of<AuthenticationService>(context, listen: false);

                await authService.deleteUser();

                beamerKey.currentState?.routerDelegate
                    .beamToNamed(Routes.homeScreen);
              },
              onCancel: () {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
