import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/controllers/drawing_board.controller.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';
import 'package:scribble/scribble.dart';

import '../models/scribble_element_model.dart';
import '../util/drawing_mode.dart';

class ScribbleElement extends HookWidget {
  const ScribbleElement({
    super.key,
    required this.scribbleElement,
    required this.controller,
    this.enabled = false,
    this.onUpdated,
    this.onDebouncedUpdate,
  });
  final ScribbleElementModel scribbleElement;
  final DrawingBoardController controller;

  final bool enabled;
  final Function(Sketch)? onUpdated;
  final Function(Sketch)? onDebouncedUpdate;

  static const int debounceTime = 1000; // ms

  @override
  Widget build(BuildContext context) {
    final debouncer = useRef<Debouncer>(Debouncer(milliseconds: debounceTime));
    final scribbleNotifier = useMemoized<ScribbleNotifier>(
      () => ScribbleNotifier(
        allowedPointersMode: ScribblePointerMode.penOnly,
        sketch: scribbleElement.sketch,
        pressureCurve: Curves.linear,
      ),
      [scribbleElement.sketch],
    );

    if (controller.drawingMode == DrawingMode.pencil) {
      scribbleNotifier.setColor(controller.penColor);
      scribbleNotifier.setStrokeWidth(controller.penSize);
    } else if (controller.drawingMode == DrawingMode.eraser) {
      scribbleNotifier.setEraser();
      scribbleNotifier.setStrokeWidth(controller.penSize);
    }

    useEffect(() {
      bool touching = false;

      // Define a listener function with the correct signature
      void listener() {
        final state = scribbleNotifier.value;
        if (scribbleElement.sketch.lines.length != state.sketch.lines.length &&
            state.activePointerIds.isEmpty &&
            touching) {
          onUpdated?.call(state.sketch);
          debouncer.value.run(() {
            onDebouncedUpdate?.call(state.sketch);
          });
        }

        if (!touching && state.activePointerIds.isNotEmpty) {
          touching = true;
        } else if (touching && state.activePointerIds.isEmpty) {
          touching = false;
        }
      }

      // Add the listener function
      scribbleNotifier.addListener(listener);

      // Return cleanup function to remove the listener
      return () {
        scribbleNotifier.removeListener(listener);
      };
    }, [scribbleNotifier]);

    useEffect(() {
      void onScribbleUpdated() {
        scribbleNotifier.setSketch(
          sketch: scribbleElement.sketch,
          addToUndoHistory: false,
        );
      }

      scribbleElement.addListener(onScribbleUpdated);

      return () {
        scribbleElement.removeListener(onScribbleUpdated);
      };
    }, [scribbleNotifier]);

    useEffect(() {
      return () {
        debouncer.value.dispose();
      };
    }, [debouncer]);

    return IgnorePointer(
      ignoring: !enabled,
      child: Stack(
        children: [
          Positioned.fill(
            child: Scribble(
              notifier: scribbleNotifier,
            ),
          )
        ],
      ),
    );
  }
}
