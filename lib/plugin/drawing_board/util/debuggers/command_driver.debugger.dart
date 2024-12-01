import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command_driver.dart';
import 'package:makernote/plugin/drawing_board/util/debuggers/command.debugger.dart';
import 'package:provider/provider.dart';

class CommandDriverDebugger extends HookWidget {
  const CommandDriverDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandDriver?>(
      builder: (context, driver, child) {
        if (driver == null) return const SizedBox();
        // expandable card
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withAlpha(169),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ExpansionTile(
            title: const Text('Command Driver'),
            tilePadding: const EdgeInsets.all(8),
            childrenPadding: const EdgeInsets.all(8),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Command Driver: ${driver.hashCode}'),
              Text('Can Execute: ${driver.canExecute}'),
              Text('Can Undo: ${driver.canUndo}'),
              Text('Can Redo: ${driver.canRedo}'),
              Text('Current Command Index: ${driver.currentIndex}'),
              Text('Command Length: ${driver.length}'),
              Text('Command Progress: ${driver.progress}'),
              Selector<CommandDriver?, List<Command>>(
                selector: (context, driver) => driver?.commands ?? [],
                builder: (context, commands, child) {
                  return CommandDebugger(
                    commands: commands,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
