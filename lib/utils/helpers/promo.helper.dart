import 'package:flutter/material.dart';
import 'package:makernote/widgets/dialogs/promo_code.dialog.dart';
import 'package:makernote/widgets/dialogs/promo_code_generation.dialog.dart';

Future showPromoCodeDialog({
  required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (context) => const PromoCodeDialog(),
  );
}

Future showGeneratePromoCodeDialog({
  required BuildContext context,
}) {
  return showDialog(
    context: context,
    builder: (context) => const PromoCodeGenerationDialog(),
  );
}
