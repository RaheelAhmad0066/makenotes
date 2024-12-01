import 'package:cloud_functions/cloud_functions.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/services/promo_code.service.dart';
import 'package:makernote/widgets/flex.extension.dart';

class PromoCodeDialog extends HookWidget {
  const PromoCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final codeController = useTextEditingController();
    final errorMessage = useState<String?>(null);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.card_giftcard),
          SizedBox(width: 10),
          Text("Promo Code"),
        ],
      ),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: FlexWithExtension.withSpacing(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          direction: Axis.vertical,
          spacing: 10,
          children: [
            const Text("Please enter your promo code."),
            const SizedBox(height: 10),
            TextFormField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: "Promo Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                errorText: errorMessage.value,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your promo code";
                }
                return null;
              },
            ),
          ],
        ),
      ),
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
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () async {
            if (codeController.text.isEmpty) {
              errorMessage.value = "Please enter your promo code";
              return;
            }
            try {
              PromoCodeService promoCodeService = PromoCodeService();
              final reward =
                  await promoCodeService.redeemPromoCode(codeController.text);

              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Congratulations!"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("You have received:"),
                        const SizedBox(height: 10),
                        Text(
                          '${reward.usageLimit} items usage limit',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${filesize(reward.mediaUsageLimit)} storage usage limit',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            } on FirebaseFunctionsException catch (e, _) {
              errorMessage.value = e.message;
              return;
            } catch (e) {
              debugPrint(e.toString());
              errorMessage.value = e.toString();
              return;
            }

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
