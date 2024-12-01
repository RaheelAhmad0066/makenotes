import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_mc_service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:provider/provider.dart';

class MCList extends HookWidget {
  const MCList({
    super.key,
    required this.controllerKey,
    required this.controller,
  });
  final String controllerKey;
  final MultiPanelController controller;

  @override
  Widget build(BuildContext context) {
    debugPrint('MCList build');
    EditorMCService mcService = Provider.of<EditorMCService>(context);
    return GestureDetector(
      behavior:
          HitTestBehavior.opaque, // Ensures entire area is swipe-sensitive
      onHorizontalDragUpdate: (details) {
        // Detect swipe to the left (swipe distance threshold to prevent accidental swipes)
        if (details.delta.dx > 15) {
          // Negative dx for leftward swipe
          debugPrint("Swipe detected");
          controller.closePanel(controllerKey);
        }
      },
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: AnimatedSize(
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 300),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 0,
                  maxWidth: 400,
                ),
                child: SizedBox(
                  width: controller.isPanelOpen(controllerKey) ? null : 0,
                  child: Visibility(
                    visible: controller.isPanelOpen(controllerKey),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: AnimatedOpacity(
                      opacity: controller.isPanelOpen(controllerKey) ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            // header
                            Row(
                              children: [
                                // title
                                Expanded(
                                  child: Text(
                                    'MC Sheet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),

                                // close button
                                IconButton(
                                  onPressed: () {
                                    controller.closePanel(controllerKey);
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),

                            const Divider(),

                            if (controller.isPanelOpen(controllerKey))
                              Expanded(
                                child: StreamBuilder(
                                    stream: mcService.getMCStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return const Center(
                                          child: Text('Something went wrong'),
                                        );
                                      }

                                      if (!snapshot.hasData) {
                                        return const SizedBox();
                                      }

                                      var mc = snapshot.data;
                                      return (mc?.length ?? 0) > 0
                                          ? ListView.builder(
                                              cacheExtent: 0.0,
                                              itemCount: mc?.length ?? 0,
                                              itemBuilder: (context, index) {
                                                // 4 radio buttons for A,B,C,D options, can be unselected
                                                return ListTile(
                                                  leading: Text(
                                                    '${index + 1}.',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  title: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      ...MCOption.values
                                                          .map((e) {
                                                        // radio button with label of option
                                                        return Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              e
                                                                  .toString()
                                                                  .split('.')
                                                                  .last,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Radio<MCOption>(
                                                              fillColor: WidgetStateProperty
                                                                  .resolveWith<
                                                                      Color>((Set<
                                                                          WidgetState>
                                                                      states) {
                                                                if (states.contains(
                                                                    WidgetState
                                                                        .selected)) {
                                                                  return Theme.of(
                                                                              context)
                                                                          .extension<
                                                                              CustomColors>()
                                                                          ?.success ??
                                                                      Colors
                                                                          .green;
                                                                }
                                                                return Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onSurface;
                                                              }),
                                                              value: e,
                                                              groupValue: mc?[
                                                                      index]
                                                                  .correctAnswer,
                                                              onChanged: mcService
                                                                      .note
                                                                      .locked
                                                                  ? null
                                                                  : (MCOption?
                                                                      value) {
                                                                      debugPrint(
                                                                          'MCList radio button changed: $value');
                                                                      mcService
                                                                          .updateMC(
                                                                        index,
                                                                        mc?[index].copyWith(
                                                                              correctAnswer: value,
                                                                            ) ??
                                                                            NoteMCModel.empty(),
                                                                      );
                                                                    },
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                  trailing: (!mcService.isOwner)
                                                      ? null
                                                      : IconButton(
                                                          onPressed: () {
                                                            debugPrint(
                                                                'MCList delete button pressed');
                                                            mcService.deleteMC(
                                                              from: index,
                                                              to: index + 1,
                                                            );
                                                          },
                                                          icon: const Icon(
                                                              Icons.delete),
                                                        ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'No MC questions',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (mcService.isOwner)
                                                    const Text(
                                                      'Tap the + button to add one',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                    }),
                              ),
                            if (mcService.isOwner) ...[
                              // space 16
                              const SizedBox(height: 16),

                              // add mc
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // dropdown menu for number of mc to add. options: 1, 5, 10
                                  MenuAnchor(
                                    menuChildren: [
                                      MenuItemButton(
                                        child: const Text('1'),
                                        onPressed: () {
                                          mcService.appendMC(1);
                                        },
                                      ),
                                      MenuItemButton(
                                        child: const Text('5'),
                                        onPressed: () {
                                          mcService.appendMC(5);
                                        },
                                      ),
                                      MenuItemButton(
                                        child: const Text('10'),
                                        onPressed: () {
                                          mcService.appendMC(10);
                                        },
                                      ),
                                    ],
                                    builder: (context, controller, child) {
                                      return IconButton(
                                        onPressed: () {
                                          if (controller.isOpen) {
                                            controller.close();
                                          } else {
                                            controller.open();
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
