import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/controllers/editor.controller.dart';
import 'package:makernote/plugin/drawing_board/services/note_stack_page.service.dart';
import 'package:makernote/plugin/drawing_board/util/drawing_mode.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/icon_box.dart';
import 'package:makernote/screens/notes/note_screen.dart';
import 'package:makernote/services/upload_service.dart';
import 'package:makernote/utils/helpers/upload.helper.dart';
import 'package:makernote/utils/note_state.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/page_model.dart';

class Toolbar extends HookWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final openPenSize = useState<bool>(false);
    return Consumer<DrawingBoardController>(
      builder: (context, controller, child) => Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
        margin: const EdgeInsets.all(0),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: kToolbarHeight,
            maxWidth: double.maxFinite,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // left side of the toolbar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<EditorController?>(
                        builder: (context, editorController, child) {
                          if (editorController == null) {
                            return const SizedBox();
                          }
                          return Wrap(
                            direction: Axis.horizontal,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              // ChangeNotifierProvider.value(
                              //   value: editorController.driver,
                              //   child: Wrap(
                              //     direction: Axis.horizontal,
                              //     alignment: WrapAlignment.start,
                              //     crossAxisAlignment: WrapCrossAlignment.center,
                              //     spacing: 10,
                              //     runSpacing: 10,
                              //     children: [
                              //       // undo
                              //       Consumer<CommandDriver?>(
                              //         builder: (context, commandDriver, child) {
                              //           if (commandDriver == null) {
                              //             return const SizedBox();
                              //           }
                              //           return IconBox(
                              //             disabled: !commandDriver.canUndo,
                              //             onTap: () {
                              //               debugPrint('pressing undo');
                              //               editorController.clearElement();
                              //               commandDriver.undo();
                              //             },
                              //             iconData: Icons.undo,
                              //             selected: false,
                              //             tooltip: 'Undo',
                              //           );
                              //         },
                              //       ),

                              //       // redo
                              //       Consumer<CommandDriver?>(
                              //         builder: (context, commandDriver, child) {
                              //           if (commandDriver == null) {
                              //             return const SizedBox();
                              //           }
                              //           return IconBox(
                              //             disabled: !commandDriver.canRedo,
                              //             onTap: () {
                              //               debugPrint('pressing redo');
                              //               editorController.clearElement();
                              //               commandDriver.redo();
                              //             },
                              //             iconData: Icons.redo,
                              //             selected: false,
                              //             tooltip: 'Redo',
                              //           );
                              //         },
                              //       ),
                              //     ],
                              //   ),
                              // ),

                              // divider box
                              const SizedBox(
                                height: 40,
                                width: 1,
                                child: VerticalDivider(),
                              ),
                              IconBox(
                                selected: controller.drawingMode ==
                                    DrawingMode.pointer,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.pointer;
                                },
                                iconData: FontAwesomeIcons.arrowPointer,
                                tooltip: "Pointer Tool",
                              ),
                              IconBox(
                                selected:
                                    controller.drawingMode == DrawingMode.text,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.text;
                                },
                                iconData: Icons.text_fields,
                                tooltip: "Text Tool",
                              ),
                              IconBox(
                                selected: controller.drawingMode ==
                                    DrawingMode.pencil,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.pencil;

                                  controller.pencilKitController?.show();
                                },
                                iconData: FontAwesomeIcons.pencil,
                                tooltip: "Drawing Tool",
                              ),
                              // IconBox(
                              //   selected: controller.drawingMode ==
                              //       DrawingMode.eraser,
                              //   onTap: () {
                              //     editorController.clearElement();
                              //     controller.drawingMode = DrawingMode.eraser;
                              //   },
                              //   iconData: FontAwesomeIcons.eraser,
                              //   tooltip: "Eraser Tool",
                              // ),
                              IconBox(
                                selected: controller.drawingMode ==
                                    DrawingMode.polygon,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.polygon;
                                },
                                iconData: FontAwesomeIcons.drawPolygon,
                                tooltip: "Polygon Tool",
                              ),
                              IconBox(
                                selected:
                                    controller.drawingMode == DrawingMode.image,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.image;
                                },
                                iconData: FontAwesomeIcons.image,
                                tooltip: "Image Tool",
                              ),
                              IconBox(
                                selected:
                                    controller.drawingMode == DrawingMode.video,
                                onTap: () {
                                  editorController.clearElement();
                                  controller.drawingMode = DrawingMode.video;
                                },
                                iconData: FontAwesomeIcons.video,
                                tooltip: "Video Tool",
                              ),

                              Consumer<NoteScreenStateWrapper>(
                                builder:
                                    (context, noteScreenStateWrapper, child) {
                                  if (<NoteScreenState>[
                                    NoteScreenState.editingTemplate
                                  ].contains(noteScreenStateWrapper.state)) {
                                    return IconBox(
                                      selected: controller.drawingMode ==
                                          DrawingMode.explanation,
                                      onTap: () {
                                        editorController.clearElement();
                                        controller.drawingMode =
                                            DrawingMode.explanation;
                                      },
                                      iconData: FontAwesomeIcons.circleQuestion,
                                      tooltip: "Explanation Tool",
                                    );
                                  } else {
                                    return const SizedBox();
                                  }
                                },
                              ),

                              ..._buildExtraTools(
                                context: context,
                                controller: controller,
                                openPenSize: openPenSize,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // some actions add the right side of the toolbar
                Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Consumer2<NoteStackPageService, EditorController?>(
                      builder: (context, noteStackPageService, editorController,
                          child) {
                        return Wrap(
                          direction: Axis.horizontal,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                            // insert page before
                            if (noteStackPageService.canInsertPage &&
                                noteStackPageService.noteStack.hasFocus)
                              IconButton(
                                onPressed: () async {
                                  editorController?.clearElement();
                                  // controller.drawingMode =
                                  //     DrawingMode.pointer;
                                  await noteStackPageService.insertPage(
                                      index: noteStackPageService
                                          .currentPageIndex);
                                  noteStackPageService.currentPageIndex++;
                                },
                                icon: const Icon(Symbols.right_panel_open),
                                tooltip: "Insert Page Before",
                              ),

                            // previous page
                            IconButton(
                              onPressed: noteStackPageService.hasPreviousPage
                                  ? () {
                                      editorController?.clearElement();
                                      // controller.drawingMode =
                                      //     DrawingMode.pointer;
                                      noteStackPageService.currentPageIndex--;
                                      debugPrint(
                                          'current page index: ${noteStackPageService.currentPageIndex}');

                                      if (controller.drawingMode ==
                                          DrawingMode.pencil) {
                                        controller.pencilKitController?.show();
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios),
                              tooltip: "Previous Page",
                            ),

                            // current page / total pages
                            Wrap(
                              direction: Axis.horizontal,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // current page dropdown
                                MenuAnchor(
                                  menuChildren: [
                                    ...List.generate(
                                      noteStackPageService.pageCount,
                                      (index) => ListTile(
                                        title: Text("${index + 1}"),
                                        onTap: () {
                                          editorController?.clearElement();
                                          // controller.drawingMode =
                                          //     DrawingMode.pointer;
                                          noteStackPageService
                                              .currentPageIndex = index;
                                          debugPrint(
                                              'current page index: ${noteStackPageService.currentPageIndex}');
                                        },
                                      ),
                                    ),
                                  ],
                                  builder: (context, controller, child) =>
                                      IconButton(
                                    icon: Text(
                                      "${noteStackPageService.currentPageIndex + 1}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                  ),
                                ),

                                // total pages
                                Text(
                                  "/ ${noteStackPageService.pageCount}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),

                            // next page
                            IconButton(
                              onPressed: noteStackPageService.hasNextPage
                                  ? () {
                                      editorController?.clearElement();
                                      // controller.drawingMode =
                                      //     DrawingMode.pointer;
                                      noteStackPageService.currentPageIndex++;
                                      debugPrint(
                                          'current page index: ${noteStackPageService.currentPageIndex}');

                                      if (controller.drawingMode ==
                                          DrawingMode.pencil) {
                                        controller.pencilKitController?.show();
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                              tooltip: "Next Page",
                            ),

                            // insert page after
                            if (noteStackPageService.canInsertPage &&
                                noteStackPageService.noteStack.hasFocus)
                              IconButton(
                                onPressed: () async {
                                  editorController?.clearElement();
                                  // controller.drawingMode =
                                  //     DrawingMode.pointer;
                                  await noteStackPageService.insertPage(
                                    index:
                                        noteStackPageService.currentPageIndex +
                                            1,
                                  );
                                },
                                icon: const Icon(Symbols.left_panel_open),
                                tooltip: "Insert Page After",
                              ),

                            // page settings
                            if (noteStackPageService.noteStack.hasFocus)
                              IconButton(
                                onPressed: () {
                                  editorController?.clearElement();
                                  controller.drawingMode = DrawingMode.pointer;
                                  final noteStackPageService =
                                      Provider.of<NoteStackPageService>(context,
                                          listen: false);

                                  showDialog(
                                    context: context,
                                    builder: (context) => PageSettingsDialog(
                                      noteStackPageService:
                                          noteStackPageService,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.settings),
                                tooltip: "Page Settings",
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExtraTools({
    required BuildContext context,
    required DrawingBoardController controller,
    required ValueNotifier<bool> openPenSize,
  }) {
    return switch (controller.drawingMode) {
      DrawingMode.pointer => [],
      DrawingMode.text => [],
      DrawingMode.pencil => _buildPencilKitTools(context, controller),
      DrawingMode.eraser => _buildEraserTools(context, controller, openPenSize),
      DrawingMode.polygon => [],
      DrawingMode.image => [],
      DrawingMode.video => [],
      DrawingMode.explanation => [],
    };
  }

  List<Widget> _buildPencilKitTools(
    BuildContext context,
    DrawingBoardController controller,
  ) {
    return [
      // const SizedBox(
      //   height: 40,
      //   width: 1,
      //   child: VerticalDivider(),
      // ),

      // // pencil picker
      // IconBox(
      //   selected: true,
      //   onTap: () {
      //     if (controller.isShowingPencilKit) {
      //       controller.pencilKitController?.hide();
      //     } else {
      //       controller.pencilKitController?.show();
      //     }
      //   },
      //   tooltip: "Pen Tools",
      //   child: Icon(
      //     Icons.color_lens,
      //     color: controller.penColor,
      //   ),
      // ),
    ];
  }

  List<Widget> _buildEraserTools(
    BuildContext context,
    DrawingBoardController controller,
    ValueNotifier<bool> openPenSize,
  ) {
    return [
      // divider box
      const SizedBox(
        height: 40,
        width: 1,
        child: VerticalDivider(),
      ),

      // pen size
      IconBox(
        selected: true,
        onTap: () {
          openPenSize.value = !openPenSize.value;
        },
        tooltip: "Pen Size",
        child: Container(
          width: controller.penSize * 2,
          height: controller.penSize * 2,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.black,
                width: 1,
              ),
            ),
          ),
        ),
      ),

      // available pen sizes(radius)
      if (openPenSize.value)
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          height: 40,
          clipBehavior: Clip.antiAlias,
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: <double>[2, 5, 10, 15]
                .map(
                  (penSize) => IconBox(
                    selected: controller.penSize == penSize,
                    size: Size(max(30, penSize * 2), max(30, penSize * 2)),
                    onTap: () {
                      controller.penSize = penSize;
                      // close pen size box
                      // openPenSize.value = false;
                    },
                    tooltip: "Pen Size $penSize",
                    child: Container(
                      width: penSize * 2,
                      height: penSize * 2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
    ];
  }
}

class PageSettingsDialog extends HookWidget {
  const PageSettingsDialog({
    super.key,
    required this.noteStackPageService,
  });

  final NoteStackPageService noteStackPageService;

  @override
  Widget build(BuildContext context) {
    final pageModel = useState<PageModel?>(null);

    useEffect(() {
      final currentPageStream = noteStackPageService
          .getCurrentPageStream(noteStackPageService.noteStack.focusedNote!.id!)
          .listen((event) {
        debugPrint('page stream view: ${event.id}');
        pageModel.value = event;
      });

      return () {
        debugPrint('page stream view: dispose');
        currentPageStream.cancel();
      };
    }, const []);

    return AlertDialog(
      title: Row(
        children: [
          const Text("Page Settings"),
          const Spacer(),
          // close button
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minWidth: 300),
        child: Builder(builder: (context) {
          if (pageModel.value == null) {
            return const SizedBox(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()));
          }
          final page = pageModel.value!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // background image
              if (noteStackPageService.canInsertPage)
                Row(
                  children: [
                    const Text("Background"),
                    const Spacer(),
                    // single-lined background option
                    IconButton.filled(
                      onPressed: () {
                        page.updateWith(
                          backgroundImageUrl: "single-line",
                        );
                        noteStackPageService.updateFocusedPage(
                          page: page,
                        );
                      },
                      icon: const Icon(Symbols.article),
                    ),

                    IconButton.filled(
                      onPressed: () async {
                        final clonePage = page.copyWith();
                        try {
                          debugPrint(
                              'updloading image on page: ${page.hashCode}, id: ${page.id}, elements: ${page.graphicElements.length}');
                          final url = await showPickFileDialog(
                              context: context,
                              fileType: FileType.image,
                              prefix: noteStackPageService
                                  .noteStack.focusedNote!.id);

                          page.updateWith(
                            backgroundImageUrl: url,
                          );
                          await noteStackPageService.updateFocusedPage(
                            page: page,
                          );
                        } catch (e) {
                          debugPrint('Error uploading image: $e');
                          page.updateWith(
                            backgroundImageUrl: clonePage.backgroundImageUrl,
                          );
                          rethrow;
                        } finally {
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      icon: page.backgroundImageUrl == null ||
                              !Uri.parse(page.backgroundImageUrl!)
                                  .hasAbsolutePath
                          ? const Icon(Icons.image)
                          : Image(
                              width: IconTheme.of(context).size,
                              height: IconTheme.of(context).size,
                              fit: BoxFit.cover,
                              image: NetworkImage(page.backgroundImageUrl!),
                            ),
                    ),

                    // remove background image
                    IconButton(
                      color: Theme.of(context).colorScheme.error,
                      onPressed: page.backgroundImageUrl != null
                          ? () async {
                              page.updateWith(
                                backgroundImageUrl: "",
                              );
                              await noteStackPageService.updateFocusedPage(
                                page: page,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              // show page size
              Row(
                children: [
                  const Text("Page Size"),
                  const Spacer(),
                  Text(
                    "${page.size.width} x ${page.size.height}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // show page order
              Row(
                children: [
                  const Text("Page Order"),
                  const Spacer(),
                  Text(
                    "${page.order + 1}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // show page elements
              Row(
                children: [
                  const Text("Page Elements"),
                  const Spacer(),
                  Text(
                    "${page.graphicElements.length}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
      actions: [
        if (noteStackPageService.canInsertPage)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Page"),
                  content: SizedBox(
                    width: 300,
                    child: const Text(
                      "Are you sure you want to delete this page?  This action cannot be undone.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // Cancel
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // Confirm
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                try {
                  await noteStackPageService.deleteCurrentPage();
                  noteStackPageService.currentPageIndex--;
                } catch (e) {
                  debugPrint('Error deleting page: $e');
                } finally {
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            child: const Text("Delete Page"),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
