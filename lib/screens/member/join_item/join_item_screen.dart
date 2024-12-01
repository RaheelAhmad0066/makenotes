import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/services/item/accessibility.service.dart';
import 'package:makernote/utils/helpers/qr_code.helper.dart';
import 'package:makernote/utils/routes.dart';
import 'package:provider/provider.dart';

class JoinItemScreen extends HookWidget {
  const JoinItemScreen({super.key, this.token});
  final String? token;

  @override
  Widget build(BuildContext context) {
    var noteToken = useState(token);
    var accessibilityService = Provider.of<AccessibilityService>(context);

    var loading = useState(false);
    var errorMessage = useState('');

    if (noteToken.value == null) {
      var formKey = GlobalKey<FormBuilderState>();
      return Center(
        child: FormBuilder(
          key: formKey,
          child: Wrap(
            direction: Axis.vertical,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: <Widget>[
              // Title
              Text(
                'Join Folder/Note',
                style: Theme.of(context).textTheme.displaySmall,
              ),

              // spacer
              const SizedBox(height: 20),

              SizedBox(
                width: 400,
                child: FormBuilderField(
                  name: 'token',
                  builder: (field) {
                    return InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Enter Token',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              name: 'tokenInput',
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                              ]),
                              inputFormatters: [
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                    return newValue.copyWith(
                                      text: newValue.text.toUpperCase(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          // scan qr code button
                          IconButton(
                            onPressed: () async {
                              try {
                                loading.value = true;
                                final code =
                                    await showScanQRCodeDialog(context);
                                if (code == null) {
                                  debugPrint("fail scan");
                                  formKey.currentState!.fields['tokenInput']
                                      ?.invalidate('Invalid QR Code');
                                  loading.value = false;
                                  return;
                                }
                                await accessibilityService
                                    .applyAccessRight(code);

                                beamerKey.currentState?.routerDelegate
                                    .beamToNamed(Routes.sharedScreen);

                                // hide error message
                                errorMessage.value = '';
                              } catch (e) {
                                formKey.currentState?.fields['tokenInput']
                                    ?.invalidate(e.toString());

                                // show error message
                                errorMessage.value = e.toString().split(':')[1];
                              } finally {
                                loading.value = false;
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Error message
              ValueListenableBuilder<String>(
                valueListenable: errorMessage,
                builder: (context, value, child) {
                  if (value.isEmpty) {
                    return const SizedBox();
                  }

                  return Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  );
                },
              ),

              // Enter button
              ElevatedButton(
                onPressed: !loading.value
                    ? () async {
                        if (formKey.currentState?.saveAndValidate() != true) {
                          return;
                        }

                        try {
                          loading.value = true;
                          await accessibilityService.applyAccessRight(
                              formKey.currentState?.value['tokenInput']);

                          beamerKey.currentState?.routerDelegate
                              .beamToNamed(Routes.sharedScreen);

                          // hide error message
                          errorMessage.value = '';
                        } catch (e) {
                          formKey.currentState?.fields['tokenInput']
                              ?.invalidate(e.toString());

                          // show error message
                          errorMessage.value = e.toString().split(':')[1];
                        } finally {
                          loading.value = false;
                        }
                      }
                    : null,
                child: loading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enter'),
              ),
            ],
          ),
        ),
      );
    } else {
      return FutureBuilder(
        future: accessibilityService.applyAccessRight(noteToken.value!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        beamerKey.currentState?.routerDelegate.beamToNamed(
                            '${Routes.joinItemScreen}/${noteToken.value}');
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            // show error
            return const Center(
              child: Text('No data'),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 600,
                child: Text(
                  'Joined ${snapshot.data}',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  beamerKey.currentState?.routerDelegate
                      .beamToNamed(Routes.sharedScreen);
                },
                child: const Text('Go to Shared'),
              ),
            ],
          );
        },
      );
    }
  }
}
