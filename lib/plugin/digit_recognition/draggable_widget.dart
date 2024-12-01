import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/digit_recognition/marking_model.dart';
import 'package:makernote/plugin/drawing_board/services/note_stack_page.service.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'predition.dart';
import 'recognizer.dart';
import 'utils.dart';

const double draggableWidth = 260.0;
double markingHeight = Constants.canvasSize;

enum DraggableContainerState {
  creating,
  editing,
  readOnly,
}

class DraggableContainer extends HookWidget {
  final List<MarkingModel> defaultMarkings;
  final String pageId;
  final DraggableContainerState state;
  final Function(List<MarkingModel>)? onMarkingsChange;
  final double? mcScore;
  final double? markingScore;
  final double? overallScore;
  final Widget? overallScoreWidget;

  const DraggableContainer({
    super.key,
    required this.pageId,
    this.defaultMarkings = const [],
    this.state = DraggableContainerState.readOnly,
    this.onMarkingsChange,
    this.mcScore,
    this.markingScore,
    this.overallScore,
    this.overallScoreWidget,
  });

  @override
  Widget build(BuildContext context) {
    final markings = useState<List<MarkingModel>>(defaultMarkings);
    final opened = useState<bool>(true);
    double initialDragX = 0;

    final canCreate = state == DraggableContainerState.creating;
    final canEdit = state == DraggableContainerState.editing;

    void adjustPositions() {
      markings.value = markings.value
        ..sort((a, b) => a.yPosition.compareTo(b.yPosition));
      for (int i = 1; i < markings.value.length; i++) {
        if (markings.value[i].yPosition - markings.value[i - 1].yPosition <
            markingHeight) {
          markings.value[i] = markings.value[i].copyWith(
              yPosition: markings.value[i - 1].yPosition + markingHeight);
        }
      }
    }

    // Add a new marking
    void addMarking(double position) {
      var newMarking = MarkingModel(
        markingId: UniqueKey().toString(),
        pageId: pageId,
        yPosition: position,
        points: [],
        name: "New Marking",
        score: 0.0,
      );

      markings.value = [...markings.value, newMarking];

      adjustPositions();

      onMarkingsChange?.call(markings.value);
    }

    // Remove a marking
    void removeMarking(double position) {
      markings.value = markings.value
          .where((element) => element.yPosition != position)
          .toList();

      adjustPositions();

      onMarkingsChange?.call(markings.value);
    }

    // Update a marking
    void updateMarking(int index, double newPosition) {
      if (index < 0 || index >= markings.value.length) return;

      var contentHeight = context.size!.height;
      if (newPosition < 0) newPosition = 0;
      if (newPosition > contentHeight - markingHeight) {
        newPosition = contentHeight - markingHeight;
      }
      markings.value = markings.value
          .map((e) => e.yPosition == markings.value[index].yPosition
              ? e.copyWith(yPosition: newPosition)
              : e)
          .toList();

      adjustPositions();

      onMarkingsChange?.call(markings.value);
    }

    void updateMarkingScore(
        String markingId, double value, List<Offset?> points) {
      var index = markings.value
          .indexWhere((element) => element.markingId == markingId);
      if (index < 0 || index >= markings.value.length) return;

      markings.value = markings.value
          .map((e) => e.yPosition == markings.value[index].yPosition
              ? e.copyWith(score: value, points: points)
              : e)
          .toList();

      debugPrint("${markings.value.length}");

      onMarkingsChange?.call(markings.value);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: opened.value ? draggableWidth : 50,
        color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(100),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                key: ValueKey(markings.value.length),
                alignment: Alignment.topCenter,
                children: [
                  RawGestureDetector(
                    gestures: <Type, GestureRecognizerFactory>{
                      DoubleTapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              DoubleTapGestureRecognizer>(
                        () => DoubleTapGestureRecognizer(),
                        (DoubleTapGestureRecognizer instance) {
                          instance.onDoubleTapDown = opened.value && canCreate
                              ? (details) {
                                  debugPrint("Double tap down");
                                  var localPosition = details.localPosition.dy;
                                  addMarking(localPosition);
                                }
                              : null;
                        },
                      ),
                      HorizontalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                        (HorizontalDragGestureRecognizer instance) {
                          instance
                            ..onStart = (details) {
                              initialDragX = details.localPosition.dx;
                            }
                            ..onUpdate = (details) {
                              final dragDistance =
                                  details.localPosition.dx - initialDragX;
                              // debugPrint("swapping $dragDistance");
                              if (dragDistance < 50) {
                                opened.value = true;
                              } else if (dragDistance > -50) {
                                opened.value = false;
                              }
                            }
                            ..onEnd = (details) {
                              initialDragX = 0; // Reset initial drag position
                            };
                        },
                      ),
                    },
                    child: null,
                  ),
                  if (opened.value)
                    ...markings.value.map(
                      (marking) {
                        return DraggableWidget(
                          readOnly: !canCreate,
                          yPosition: marking.yPosition,
                          onDragEnd: !canCreate
                              ? (details) {}
                              : (details) {
                                  var index = markings.value.indexWhere(
                                      (element) =>
                                          element.yPosition ==
                                          marking.yPosition);

                                  var localOffsetDy =
                                      (context.findRenderObject() as RenderBox)
                                          .globalToLocal(details.offset)
                                          .dy;

                                  updateMarking(index, localOffsetDy);
                                },
                          onDismissed: !canCreate
                              ? () {}
                              : () {
                                  removeMarking(marking.yPosition);
                                },
                          child: DigitRecognition(
                            readOnly: !canEdit,
                            defaultPrediction: marking.score.toString(),
                            defaultPoints: marking.points,
                            markingHeight: markingHeight,
                            onValueChange: !canEdit
                                ? (score, points) {}
                                : (score, points) {
                                    if (marking.markingId == null) return;
                                    updateMarkingScore(
                                        marking.markingId!, score, points);
                                  },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (opened.value) ...[
              Container(
                width: draggableWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(160),
                ),
                child: Text(
                  (markings.value.fold(0.0, (sum, item) => sum + item.score))
                      .toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.red,
                  ),
                ),
              ),
              if (overallScoreWidget != null) overallScoreWidget!,
              if (overallScore != null &&
                  mcScore != null &&
                  markingScore != null)
                Container(
                  width: draggableWidth,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                  ),
                  child: Text(
                    "($mcScore) + ($markingScore) = $overallScore",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class OverallScoreWidget extends HookWidget {
  const OverallScoreWidget({
    super.key,
    required this.templateReference,
    required this.exerciseReference,
  });

  final NoteModel templateReference;
  final NoteModel exerciseReference;

  @override
  Widget build(BuildContext context) {
    final mcService = Provider.of<MCService>(context);
    final noteStackPageService = Provider.of<NoteStackPageService>(context);
    final markingScore = noteStackPageService.currentPage?.order == 0
        ? noteStackPageService.getOverallMarkingScore()
        : null;
    return FutureBuilder(
      future: Future.wait(
        [
          mcService.getMC(templateReference.id!, templateReference.ownerId),
          mcService.getMC(exerciseReference.id!, exerciseReference.ownerId),
        ],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: draggableWidth,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(160),
            ),
            child: const Text(
              "Loading...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: Colors.red,
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            width: draggableWidth,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(160),
            ),
            child: const Text(
              "--",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: Colors.red,
              ),
            ),
          );
        }
        final mcTemplate = snapshot.data![0];
        final mcExercise = snapshot.data![1];
        final mcScore = mcExercise
            .where((element) =>
                element.correctAnswer ==
                mcTemplate[mcExercise.indexOf(element)].correctAnswer)
            .length;
        return Container(
          width: draggableWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(160),
          ),
          child: Text(
            "($mcScore) + (${markingScore ?? 0}) = ${mcScore + (markingScore ?? 0)}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }
}

class DigitRecognition extends HookWidget {
  const DigitRecognition({
    super.key,
    this.readOnly = false,
    this.defaultPrediction = "0",
    this.defaultPoints = const [],
    required this.markingHeight,
    required this.onValueChange,
  });

  final bool readOnly;
  final String defaultPrediction;
  final List<Offset?> defaultPoints;
  final double markingHeight;
  final Function(double score, List<Offset?> points) onValueChange;

  @override
  Widget build(BuildContext context) {
    final points = useState<List<Offset?>>(defaultPoints);
    final recognizer = useRef(Recognizer());
    final predictions = useState<List<Prediction>>([]);

    useEffect(
      () {
        try {
          if (!readOnly) {
            recognizer.value.loadModel();
          }
        } catch (e) {
          debugPrint("Error loading model: $e");
        }
        return () {
          recognizer.value.dispose();
          predictions.value.clear();
          points.value.clear();
        };
      },
      const [],
    );

    final mostLikelyPrediction = useState(defaultPrediction);
    final TextEditingController controller =
        useTextEditingController(text: mostLikelyPrediction.value);

    useEffect(() {
      void listener() {
        if (controller.text != mostLikelyPrediction.value) {
          controller.text = mostLikelyPrediction.value;
          var parse = double.tryParse(mostLikelyPrediction.value);
          if (parse != null) {
            onValueChange(parse, points.value);
          }
        }
      }

      mostLikelyPrediction.addListener(listener);
      return () {
        mostLikelyPrediction.removeListener(listener);
      };
    }, [mostLikelyPrediction]);

    useEffect(() {
      bool isMounted = true; // Flag to track if widget is still mounted

      void updatePrediction() {
        if (!isMounted) return; // Check if the widget is still mounted

        final score = double.tryParse(controller.text) ?? 0;
        mostLikelyPrediction.value = controller.text;
        onValueChange(score, points.value);
      }

      controller.addListener(updatePrediction);

      return () {
        isMounted = false; // Mark as unmounted
        controller.removeListener(updatePrediction);
        // controller.dispose(); // Dispose the controller when the widget unmounts
      };
    }, [controller]);

    void recognize() async {
      List<dynamic>? pred = await recognizer.value.recognize(points.value);

      if (!context.mounted || pred == null) {
        return;
      }

      for (var element in pred) {
        debugPrint("Element: $element");
      }

      predictions.value =
          pred.map((json) => Prediction.fromJson(json)).toList();

      debugPrint("Predictions: ${predictions.value}");

      mostLikelyPrediction.value = predictions.value
          .reduce((value, element) =>
              value.confidence > element.confidence ? value : element)
          .label;
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          width: markingHeight,
          height: markingHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withAlpha(100)),
          ),
          child: RawGestureDetector(
            gestures: readOnly
                ? <Type, GestureRecognizerFactory>{}
                : <Type, GestureRecognizerFactory>{
                    PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                        PanGestureRecognizer>(
                      () => PanGestureRecognizer(),
                      (PanGestureRecognizer instance) {
                        instance
                          ..onStart = (details) {
                            // Handle onPanStart if needed
                          }
                          ..onUpdate = (details) {
                            debugPrint("update points");
                            Offset localPosition = details.localPosition;
                            if (localPosition.dx >= 0 &&
                                localPosition.dx <= markingHeight &&
                                localPosition.dy >= 0 &&
                                localPosition.dy <= markingHeight) {
                              points.value = [...points.value, localPosition];
                            }
                          }
                          ..onEnd = (details) {
                            debugPrint("draw end");
                            points.value = [...points.value, null];
                            recognize();
                          };
                      },
                    ),
                  },
            child: CustomPaint(
              painter: DrawingPainter(points.value, Colors.red),
            ),
          ),
        ),
        Container(
          color: Colors.white.withAlpha(160),
          width: 68,
          height: markingHeight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  DecimalTextInputFormatter(decimalRange: 1),
                ],
                style: const TextStyle(fontSize: 20.0, color: Colors.red),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                readOnly: readOnly,
              ),
              if (!readOnly)
                // clear button
                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        points.value = [];
                        mostLikelyPrediction.value = "0";
                      },
                      child: const Icon(Symbols.ink_eraser),
                    ),
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Allow empty input
    if (newText.isEmpty) {
      return newValue;
    }

    // Allow digits and single decimal point
    final regExp = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regExp.hasMatch(newText)) {
      return newValue;
    }

    // If the new value is not valid, return the old value
    return oldValue;
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;
  final Paint _paint; // Avoid creating new Paint objects repeatedly.

  DrawingPainter(this.points, this.strokeColor)
      : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    // Only repaint when points or stroke color changes.
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class DraggableWidget extends HookWidget {
  final double yPosition;
  final Widget? child;
  final Function(DraggableDetails) onDragEnd;
  final VoidCallback onDismissed;
  final bool readOnly;

  const DraggableWidget({
    super.key,
    required this.yPosition,
    this.child,
    required this.onDragEnd,
    required this.onDismissed,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDismissing = useState(false);

    return Positioned(
      top: yPosition,
      child: SizedBox(
        width: draggableWidth,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!readOnly)
              // Handle for dragging
              GestureDetector(
                // onPanStart: (details) {
                //   initialDragX = details.localPosition.dx;
                // },
                onTap: !isDismissing.value
                    ? null
                    : () {
                        onDismissed();
                      },
                onPanUpdate: isDismissing.value
                    ? null
                    : (details) {
                        var newOffset = details.globalPosition.dy;
                        // Call onDragEnd with a dummy DraggableDetails since we're not using velocity
                        onDragEnd(DraggableDetails(
                          velocity: Velocity.zero,
                          offset: Offset(
                            details.globalPosition.dx,
                            newOffset,
                          ),
                        ));
                      },
                onLongPress: () async {
                  isDismissing.value = true;

                  await Future.delayed(const Duration(milliseconds: 1500));

                  isDismissing.value = false;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDismissing.value
                        ? Colors.red.withAlpha(50)
                        : Colors.white.withAlpha(160),
                  ),
                  height: markingHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: 40.0,
                      color: Colors.transparent,
                      child: Center(
                        child: isDismissing.value
                            ? const Icon(Icons.close, color: Colors.red)
                            : const Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            if (child != null)
              // Main child widget with CustomPaint support
              child!,
          ],
        ),
      ),
    );
  }
}
