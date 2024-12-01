import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/models/explanation_element_model.dart';
import 'package:makernote/plugin/drawing_board/util/commands/lib/create.command.dart';
import 'package:makernote/plugin/drawing_board/util/show_dialogs.dart';
import 'package:provider/provider.dart';

import '../../models/note_model.dart';
import '../../screens/notes/note_screen.dart';
import '../../utils/note_state.dart';
import 'controllers/drawing_board.controller.dart';
import 'controllers/editor.controller.dart';
import 'graphic_elements/base_graphic_element.dart';
import 'graphic_elements/flutter_drawing_board_element.dart';
import 'models/flutter_drawing_board_model.dart';
import 'models/graphic_element_model.dart';
import 'models/page_model.dart';
import 'package:makernote/plugin/drawing_board/util/commands/lib/update_drawingboard.command.dart';
import 'util/drawing_mode.dart';
import 'util/painters/single_line_background.painter.dart';
import 'util/widgets/drawing_controls.dart';
import 'util/widgets/element_creator.dart';
import 'util/widgets/element_editor.dart';

class PageRenderer extends HookWidget {
  const PageRenderer({super.key, this.isEditable = false});
  final bool isEditable;

  void logImageCacheSize() {
    // Get the current number of cached images
    int cachedImageCount = PaintingBinding.instance.imageCache.currentSize;

    // Get the total size of all cached images in bytes
    int cachedImageSize = PaintingBinding.instance.imageCache.currentSizeBytes;

    debugPrint('Cached Images Count: $cachedImageCount');
    debugPrint('Cached Images Size: ${cachedImageSize / (1024 * 1024)} MB');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('building page renderer: ${context.hashCode}');

    return Selector<PageModel, Size>(
      selector: (context, page) => page.size,
      builder: (context, size, child) {
        return Container(
          clipBehavior: Clip.none,
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // background image
              Selector<PageModel, String?>(
                selector: (context, page) => page.backgroundImageUrl,
                builder: (context, imagePath, child) {
                  if (imagePath == null) return const SizedBox();

                  if (imagePath == "single-line") {
                    return Positioned.fill(
                      child: CustomPaint(
                        painter: SingleLineBackgroundPainter(
                          lineThickness: 1.0,
                          lineSpacing: PageModel.a4.height * (8 / 297), // 8mm
                          padding: EdgeInsets.only(
                            top: PageModel.a4.height * (3 * 8 / 297),
                            bottom: PageModel.a4.height * (2 * 8 / 297),
                            left: PageModel.a4.width * (2 * 8 / 297),
                            right: PageModel.a4.width * (2 * 8 / 297),
                          ),
                        ),
                      ),
                    );
                  }

                  return Positioned.fill(
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          logImageCacheSize();
                          return child;
                        }

                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Failed to load image');
                      },
                    ),
                  );
                },
              ),

              // close editable element on click outside
              if (isEditable)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      var editorController = Provider.of<EditorController?>(
                          context,
                          listen: false);
                      editorController?.clearElement();
                    },
                  ),
                ),

              // render all elements
              Selector<PageModel, List<GraphicElementModel>>(
                selector: (context, pageModel) => pageModel.graphicElements,
                shouldRebuild: (previous, next) => true,
                builder: (context, graphicElements, child) {
                  return Positioned.fill(
                    child: Stack(
                      children: [
                        for (var i = 0; i < graphicElements.length; i++)
                          MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(
                                value: graphicElements[i],
                              ),
                            ],
                            builder: (context, child) {
                              if (graphicElements[i].type ==
                                  GraphicElementType.explanation) {
                                return const SizedBox();
                              }
                              return Consumer<GraphicElementModel>(
                                builder: (context, element, child) {
                                  return Consumer<EditorController?>(
                                    builder:
                                        (context, editorController, child) {
                                      if (isEditable &&
                                          i == editorController?.elementIndex) {
                                        return const SizedBox();
                                      } else {
                                        return Positioned.fromRect(
                                          rect: element.bounds,
                                          child: IgnorePointer(
                                            ignoring: element.type ==
                                                GraphicElementType.drawing,
                                            child: BaseGraphicElement(
                                              graphicElement: element,
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: !isEditable
                                                    ? null
                                                    : () {
                                                        editorController
                                                            ?.setElement(
                                                                element, i);
                                                      },
                                                child: GraphicElementModel
                                                    .getElementWidget(
                                                  element: element,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        if (isEditable)
                          for (var i = 0; i < graphicElements.length; i++)
                            MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: graphicElements[i],
                                ),
                              ],
                              builder: (context, child) {
                                final noteStack =
                                    Provider.of<NoteModelStack>(context);
                                final stateWrapper =
                                    Provider.of<NoteScreenStateWrapper?>(
                                        context);
                                if (graphicElements[i].type !=
                                        GraphicElementType.explanation ||
                                    (noteStack.template.hideExplanation ==
                                            true &&
                                        stateWrapper?.state !=
                                            NoteScreenState.editingTemplate)) {
                                  return const SizedBox();
                                }
                                return Consumer<GraphicElementModel>(
                                  builder: (context, element, child) {
                                    return Consumer<EditorController?>(
                                      builder:
                                          (context, editorController, child) {
                                        if (isEditable &&
                                            i ==
                                                editorController
                                                    ?.elementIndex) {
                                          return const SizedBox();
                                        } else {
                                          return Positioned.fromRect(
                                            rect: element.bounds,
                                            child: IgnorePointer(
                                              ignoring: element.type ==
                                                  GraphicElementType.drawing,
                                              child: BaseGraphicElement(
                                                graphicElement: element,
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: !isEditable
                                                      ? null
                                                      : () {
                                                          editorController
                                                              ?.setElement(
                                                                  element, i);
                                                        },
                                                  child: GraphicElementModel
                                                      .getElementWidget(
                                                    element: element,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                      ],
                    ),
                  );
                },
              ),

              // render flutter drawing board
              Consumer<DrawingBoardController>(
                builder: (context, controller, child) {
                  return Selector<PageModel, FlutterDrawingBoardModel>(
                    selector: (context, page) => page.flutterDrawingBoardModel,
                    builder: (context, flutterDrawingBoardModel, child) {
                      return Stack(
                        children: [
                          IgnorePointer(
                            ignoring: !(isEditable &&
                                [
                                  DrawingMode.eraser,
                                  DrawingMode.pencil,
                                ].contains(controller.drawingMode)),
                            child: FlutterDrawingBoardElement(
                              enabled: isEditable &&
                                  [
                                    DrawingMode.eraser,
                                    DrawingMode.pencil,
                                  ].contains(controller.drawingMode),
                              controller: controller,
                              drawingBoardElement: flutterDrawingBoardModel,
                              onDebouncedUpdate: (element) {
                                final editorController =
                                    Provider.of<EditorController?>(context,
                                        listen: false);
                                editorController?.driver.execute(
                                  UpdateDrawingBoardCommand(
                                    pageService:
                                        editorController.editorPageService,
                                    pageModel: editorController.pageModel,
                                    newData: element,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              // render sketch
              // if (Theme.of(context).platform != TargetPlatform.iOS && false)
              //   Consumer<DrawingBoardController>(
              //     builder: (context, controller, child) {
              //       return Selector<PageModel, ScribbleElementModel>(
              //         selector: (context, page) => page.sketch,
              //         builder: (context, sketchModel, child) {
              //           return IgnorePointer(
              //             ignoring: !(isEditable &&
              //                 [
              //                   DrawingMode.eraser,
              //                   DrawingMode.pencil,
              //                 ].contains(controller.drawingMode)),
              //             child: ScribbleElement(
              //               enabled: isEditable &&
              //                   [
              //                     DrawingMode.eraser,
              //                     DrawingMode.pencil,
              //                   ].contains(controller.drawingMode),
              //               controller: controller,
              //               scribbleElement: sketchModel,
              //               onDebouncedUpdate: (element) {
              //                 final editorController =
              //                     Provider.of<EditorController?>(context,
              //                         listen: false);
              //                 editorController?.driver.execute(
              //                   UpdateSketchCommand(
              //                     pageService:
              //                         editorController.editorPageService,
              //                     pageModel: editorController.pageModel,
              //                     newSketch: element,
              //                   ),
              //                 );
              //               },
              //             ),
              //           );
              //         },
              //       );
              //     },
              //   ),

              // render pencil kit
              // if (Theme.of(context).platform == TargetPlatform.iOS && false)
              //   Consumer<DrawingBoardController>(
              //     builder: (context, controller, child) {
              //       return Selector<PageModel, PencilKitElementModel>(
              //         selector: (context, page) => page.pencilKit,
              //         builder: (context, pencilKitModel, child) {
              //           return IgnorePointer(
              //             ignoring: !(isEditable &&
              //                 [
              //                   DrawingMode.pencil,
              //                 ].contains(controller.drawingMode)),
              //             child: PencilKitElement(
              //               enabled: isEditable &&
              //                   [
              //                     DrawingMode.pencil,
              //                   ].contains(controller.drawingMode),
              //               drawingBoardController: controller,
              //               pencilKitElement: pencilKitModel,
              //               onDebouncedUpdate: (element) {
              //                 final editorController =
              //                     Provider.of<EditorController?>(context,
              //                         listen: false);
              //                 editorController?.driver.execute(
              //                   UpdatePencilKitCommand(
              //                     pageService:
              //                         editorController.editorPageService,
              //                     pageModel: editorController.pageModel,
              //                     newData: element,
              //                   ),
              //                 );
              //               },
              //             ),
              //           );
              //         },
              //       );
              //     },
              //   ),

              // render editable element, except when drawing mode is eraser or pencil
              if (isEditable)
                Consumer<EditorController?>(
                  builder: (context, editorController, child) {
                    if (editorController == null) return const SizedBox();
                    if (editorController.hasElement) {
                      return Selector<DrawingBoardController, double>(
                        selector: (context, controller) =>
                            controller.currentScale,
                        builder: (context, scale, child) {
                          return MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(
                                value: editorController.elementState!,
                              ),
                            ],
                            child: ElementEditor(
                              scale: scale,
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),

              if (isEditable)
                Consumer<EditorController?>(
                  builder: (context, editorController, child) {
                    return EditorCreator(
                      onCreated: (element) async {
                        if (element is ExplanationElementModel) {
                          if (editorController?.editorPageService.note.id ==
                              null) {
                            debugPrint('No focused note');
                            return;
                          }
                          // open explanation dialog
                          await showExplanationDialog(
                            context: context,
                            explanationElement: element,
                            controller: editorController,
                            noteId:
                                editorController!.editorPageService.note.id!,
                          );
                        }
                        editorController?.driver.execute(
                          CreateCommand(
                            newElement: element,
                            pageService: editorController.editorPageService,
                            pageModel: editorController.pageModel,
                          ),
                        );
                      },
                      onCancel: () {},
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
