import 'package:flutter/material.dart';
import 'package:makernote/services/authentication_service.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/helpers/upload.helper.dart';
import 'package:makernote/widgets/dialogs/user_delete.dialog.dart';
import 'package:makernote/widgets/dialogs/user_display_name.dialog.dart';
import 'package:makernote/widgets/dialogs/user_reauthenticate.dialog.dart';
import 'package:provider/provider.dart';

Future showUpdateDisplayNameDialog({
  required BuildContext context,
  required String? displayName,
}) {
  return showDialog(
    context: context,
    builder: (context) => UserDisplayNameDialog(
      displayName: displayName,
    ),
  );
}

Future showReauthenticateDialog({
  required BuildContext context,
  Function? onSuccess,
  Function(String)? onFailure,
  Function? onCancel,
}) {
  return showDialog(
    context: context,
    builder: (context) => UserReauthenticationDialog(
      onSuccess: onSuccess,
      onFailure: onFailure,
      onCancel: onCancel,
    ),
  );
}

Future showDeleteUserDialog({
  required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (context) => const UserDeleteDialog(),
  );
}

updateUserPhotoUrl({
  required BuildContext context,
}) async {
  final authService =
      Provider.of<AuthenticationService>(context, listen: false);
  final url = await showPickFileDialog(
    context: context,
    fileType: FileType.image,
  );

  await authService.updatePhotoURL(url);
}
