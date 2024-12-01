import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:provider/provider.dart';

class UserDisplayNameDialog extends HookWidget {
  const UserDisplayNameDialog({
    super.key,
    required this.displayName,
  });

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final TextEditingController folderNameController =
        TextEditingController(text: displayName);
    return AlertDialog(
      title: const Text('Update Display Name'),
      content: Form(
          child: TextFormField(
        controller: folderNameController,
      )),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).hintColor,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel')),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
              try {
                await authService
                    .updateDisplayName(folderNameController.value.text);

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Display name updated'),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                  ),
                );
              }
            },
            child: const Text('Update')),
      ],
    );
  }
}
