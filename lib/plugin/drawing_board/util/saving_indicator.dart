import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command_driver.dart';
import 'package:provider/provider.dart';

class SavingIndicator extends HookWidget {
  const SavingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final commandDriver = Provider.of<CommandDriver?>(context);
    if (commandDriver == null) return const SizedBox();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: commandDriver.processingQueue
          ? Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Center(
                  child: Text(
                    'Saving...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                  ),
                ),
              ),
            )
          : const SizedBox(),
    );
  }
}
