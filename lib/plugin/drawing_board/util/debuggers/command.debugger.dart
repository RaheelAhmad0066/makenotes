import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command.dart';

class CommandDebugger extends HookWidget {
  const CommandDebugger({
    super.key,
    required this.commands,
  });

  final List<Command> commands;

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) return const SizedBox();
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(169),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListView.builder(
        cacheExtent: 0.0,
        itemCount: commands.length,
        itemBuilder: (context, index) {
          var command = commands[index];
          return ExpansionTile(
            title: Text('Command $index: ${command.hashCode}'),
            tilePadding: const EdgeInsets.all(8),
            childrenPadding: const EdgeInsets.all(8),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Command: ${command.hashCode}'),
              Text(command.toString()),
            ],
          );
        },
      ),
    );
  }
}
