import 'package:flutter/material.dart';
import 'package:makernote/widgets/dialogs/privacy_policy.dialog.dart';
import 'package:makernote/widgets/dialogs/terms_of_service.dialog.dart';

Future showTermsOfServiceDialog({
  required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (context) => const TermsOfServiceDialog(),
  );
}

Future showPrivacyPolicyDialog({
  required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (context) => const PrivacyPolicyDialog(),
  );
}
