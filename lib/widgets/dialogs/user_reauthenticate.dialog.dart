import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:provider/provider.dart';

class UserReauthenticationDialog extends HookWidget {
  const UserReauthenticationDialog({
    super.key,
    required this.onSuccess,
    required this.onFailure,
    required this.onCancel,
  });

  // on success
  final Function? onSuccess;
  // on failure
  final Function(String)? onFailure;
  // on cancel
  final Function? onCancel;

  @override
  Widget build(BuildContext context) {
    final passwordController = useTextEditingController();
    final errorMessage = useState<String?>(null);
    return AlertDialog(
      title: const Text("Reauthenticate"),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: FlexWithExtension.withSpacing(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          direction: Axis.vertical,
          spacing: 10,
          children: [
            const Text("Please reauthenticate to continue."),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                errorText: errorMessage.value,
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        // cancel button
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).hintColor,
          ),
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: const Text("Cancel"),
        ),

        // with google button
        TextButton.icon(
          onPressed: () async {
            final authService =
                Provider.of<AuthenticationService>(context, listen: false);
            try {
              await authService.reauthenticateWithGoogle(context);
              onSuccess?.call();
              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              debugPrint('error: $e');
              if (context.mounted) {
                // show dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Error"),
                    content: const Text(
                        "An error occured while trying to reauthenticate with Google."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          icon: const Icon(
            FontAwesomeIcons.google,
            size: 16,
          ),
          label: const Text("Continue with Google"),
        ),

        // with apple button
        if (Theme.of(context).platform == TargetPlatform.iOS)
          TextButton.icon(
            onPressed: () async {
              final authService =
                  Provider.of<AuthenticationService>(context, listen: false);
              try {
                await authService.reauthenticateWithApple(context);
                onSuccess?.call();
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                debugPrint('error: $e');
                if (context.mounted) {
                  // show dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Error"),
                      content: const Text(
                          "An error occured while trying to reauthenticate with Apple."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            icon: const Icon(
              FontAwesomeIcons.apple,
              size: 16,
            ),
            label: const Text("Continue with Apple"),
          ),

        // continue button
        TextButton(
          onPressed: () async {
            final authService =
                Provider.of<AuthenticationService>(context, listen: false);
            try {
              await authService.reauthenticate(passwordController.text);
              onSuccess?.call();
              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              passwordController.clear();

              errorMessage.value = "Invalid password";
            }
          },
          child: const Text("Continue"),
        ),
      ],
    );
  }
}
