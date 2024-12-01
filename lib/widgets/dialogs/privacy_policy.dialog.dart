import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyDialog extends HookWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: rootBundle.loadString("assets/privacy.md"),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: IgnorePointer(
                            child: Markdown(
                              shrinkWrap: true,
                              softLineBreak: true,
                              data: snapshot.data!,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
