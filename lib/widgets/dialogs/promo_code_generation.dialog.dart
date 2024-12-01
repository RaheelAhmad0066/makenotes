import 'package:cloud_functions/cloud_functions.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:makernote/services/promo_code.service.dart';
import 'package:material_symbols_icons/symbols.dart';

class PromoCodeGenerationDialog extends HookWidget {
  const PromoCodeGenerationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    var formKey = GlobalKey<FormBuilderState>();
    final errorMessage = useState<String?>(null);
    final isSubmitting = useState<bool>(false);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Symbols.manufacturing),
          SizedBox(width: 10),
          Text("Generate A Promo Code"),
        ],
      ),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 500,
          height: 500,
          child: Center(
            child: FormBuilder(
              key: formKey,
              child: Wrap(
                direction: Axis.vertical,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                children: <Widget>[
                  // Title
                  Text(
                    'Generate a promo code to share with your customers.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),

                  // spacer
                  const SizedBox(height: 20),

                  // custom code
                  SizedBox(
                    width: 300,
                    child: FormBuilderTextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Custom Code(Optional)',
                      ),
                      name: 'code',
                      validator: FormBuilderValidators.compose([
                        // alphanumeric
                        FormBuilderValidators.match(
                          RegExp(r'^[a-zA-Z0-9]+$'),
                          errorText: 'Only alphanumeric characters are allowed',
                        ),
                      ]),
                    ),
                  ),

                  // max redemptions
                  SizedBox(
                    width: 300,
                    child: FormBuilderTextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Max Redemptions',
                      ),
                      initialValue: '1',
                      name: 'maxRedemptions',
                      // numeric or empty
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(1),
                      ]),
                    ),
                  ),

                  // usage limit
                  SizedBox(
                    width: 300,
                    child: FormBuilderTextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Usage Limit',
                      ),
                      initialValue: '100',
                      name: 'usageLimit',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(1),
                      ]),
                    ),
                  ),

                  // storage limit
                  SizedBox(
                    width: 300,
                    child: FormBuilderField(
                      name: 'mediaUsageLimit',
                      initialValue: '${1024 * 1024 * 1024}',
                      builder: (field) {
                        return InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Storage Limit',
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  initialValue: '${1}',
                                  name: 'mediaUsageLimitValue',
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.numeric(),
                                    FormBuilderValidators.min(1),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // unit selector
                              SizedBox(
                                width: 100,
                                child: FormBuilderDropdown(
                                  name: 'mediaUsageLimitUnit',
                                  initialValue: '${1024 * 1024 * 1024}',
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  items: [
                                    '${1024}',
                                    '${1024 * 1024}',
                                    '${1024 * 1024 * 1024}',
                                    '${1024 * 1024 * 1024 * 1024}',
                                  ].map((value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        filesize(int.parse(value))
                                            .split(' ')[1],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // expiry duration (in seconds)
                  SizedBox(
                    width: 300,
                    child: FormBuilderTextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Expiry Duration (in seconds)',
                      ),
                      initialValue: '86400',
                      name: 'expiry',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(1),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          onPressed: isSubmitting.value
              ? null
              : () async {
                  if (formKey.currentState == null) return;
                  if (formKey.currentState?.saveAndValidate() != true) return;
                  debugPrint(formKey.currentState?.value['maxRedemptions']);
                  try {
                    PromoCodeService promoCodeService = PromoCodeService();
                    final promoCode = await promoCodeService.generateCode(
                      customCode: formKey.currentState?.value['code'],
                      maxRedemptions: (formKey.currentState
                                      ?.value['maxRedemptions'] as String?)
                                  ?.isNotEmpty ==
                              true
                          ? int.parse(
                              formKey.currentState?.value['maxRedemptions'],
                            )
                          : null,
                      usageLimit: int.parse(
                        formKey.currentState?.value['usageLimit'] ?? '1',
                      ),
                      mediaUsageLimit: int.parse(
                            formKey.currentState
                                    ?.value['mediaUsageLimitValue'] ??
                                '1',
                          ) *
                          int.parse(
                            formKey.currentState
                                    ?.value['mediaUsageLimitUnit'] ??
                                '1',
                          ),
                      expiryDuration: int.parse(
                        formKey.currentState?.value['expiry'] ?? '1',
                      ),
                    );

                    if (context.mounted) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Promo Code Generated"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text("Your promo code is:"),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content:
                                          Text('Copied token to clipboard'),
                                    ),
                                  );
                                  Clipboard.setData(
                                    ClipboardData(text: promoCode.code),
                                  );
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        promoCode.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge,
                                      ),
                                      const SizedBox(width: 8.0),
                                      const Icon(Icons.copy),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Max Redemptions: ${promoCode.maxRedemptions}',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Usage Limit: ${promoCode.reward.usageLimit}',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Storage Limit: ${filesize(promoCode.reward.mediaUsageLimit)}',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Expiry: ${DateFormat.yMd().add_jm().format(promoCode.expiresAt.toDate())}',
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
