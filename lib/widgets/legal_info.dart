import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/utils/helpers/legal.helper.dart';
import 'package:makernote/widgets/flex.extension.dart';

class LegalInfo extends HookWidget {
  const LegalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    // copy right year that start from 2023. Show [2023 - x] where x is the current year
    final String year = useMemoized(() {
      final int currentYear = DateTime.now().year;
      return currentYear > 2023 ? "2023 - $currentYear" : "2023";
    });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FlexWithExtension.withSpacing(
        direction: Axis.vertical,
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              text: "",
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: "Terms of Service",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await showTermsOfServiceDialog(context: context);
                    },
                ),

                // privacy policy
                const TextSpan(text: " | "),

                TextSpan(
                  text: "Privacy Policy",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await showPrivacyPolicyDialog(context: context);
                    },
                ),
              ],
            ),
          ),

          // copy right
          Text(
            "© $year TacklEd Innovation. All rights reserved.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
