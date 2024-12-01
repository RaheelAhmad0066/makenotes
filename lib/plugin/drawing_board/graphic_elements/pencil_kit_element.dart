import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/util/drawing_mode.dart';
import 'package:pencil_kit/pencil_kit.dart';
import 'package:provider/provider.dart';

import '../controllers/drawing_board.controller.dart';
import '../models/pecil_kit_element.model.dart';
import '../services/timer_service.dart';
import '../util/debouncer.dart';

class PencilKitElement extends HookWidget {
  const PencilKitElement({
    super.key,
    required this.pencilKitElement,
    required this.drawingBoardController,
    this.enabled = false,
    this.onUpdated,
    this.onDebouncedUpdate,
  });

  final PencilKitElementModel pencilKitElement;
  final DrawingBoardController drawingBoardController;

  final bool enabled;
  final Function(String?)? onUpdated;
  final Function(String?)? onDebouncedUpdate;

  static const int debounceTime = 1000; // ms

  @override
  Widget build(BuildContext context) {
    debugPrint("Rendering Pencil Kit Element");

    final controllerRef = useRef<PencilKitController?>(null);
    final saveTimer = Provider.of<TimerService>(context);
    final debouncer =
        useRef<Debouncer>(Debouncer(milliseconds: debounceTime, leading: true));
    final lastData = useRef<DataToCheck?>(null);

    final getUpdateData = useCallback(({bool force = false}) async {
      final data = await controllerRef.value?.getBase64Data();
      if (data == null) return null;

      if (force) return data;

      // Extract first and last characters for comparison
      String firstChar = data.isNotEmpty ? data.substring(0, 1) : '';
      String lastChar = data.isNotEmpty ? data.substring(data.length - 1) : '';

      if (lastData.value?.length != data.length ||
          lastData.value?.firstChar != firstChar ||
          lastData.value?.lastChar != lastChar) {
        lastData.value = DataToCheck(
          length: data.length,
          firstChar: firstChar,
          lastChar: lastChar,
        );

        return data;
      }
      return null;
    }, []);

    final triggerUpdate = useCallback(() async {
      debugPrint("[${pencilKitElement.hashCode}] Trigger Update");
      final data = await getUpdateData();

      if (data == null) return;

      // Proceed with the update
      onUpdated?.call(data);
      onDebouncedUpdate?.call(data);
    }, [getUpdateData, onUpdated, onDebouncedUpdate]);

    useEffect(() {
      if (enabled && controllerRef.value != null) {
        debugPrint("enable changed");
        drawingBoardController.pencilKitController = controllerRef.value;
        drawingBoardController.pencilKitController?.show();
      } else {
        debugPrint("disable changed");
        controllerRef.value?.hide();
        if (drawingBoardController.pencilKitController == controllerRef.value) {
          // drawingBoardController.pencilKitController?.dispose();
          drawingBoardController.pencilKitController = null;
        }
      }
      return () {
        if (drawingBoardController.pencilKitController == controllerRef.value) {
          // drawingBoardController.pencilKitController?.dispose();
          drawingBoardController.pencilKitController = null;
          debouncer.value.dispose();
        }
      };
    }, [enabled]);

    useEffect(() {
      debugPrint("PencilKitElement [${pencilKitElement.hashCode}] mounted");
      return () {
        debugPrint("PencilKitElement [${pencilKitElement.hashCode}] disposed");
        // controllerRef.value?.dispose();
        controllerRef.value = null;
        // drawingBoardController.pencilKitController?.dispose();
        drawingBoardController.pencilKitController = null;
        debouncer.value.dispose();
        pencilKitElement.dispose();
      };
    }, []);

    useEffect(() {
      if (pencilKitElement.data != null) {
        controllerRef.value?.loadBase64Data(pencilKitElement.data!);
      }
      return () {
        // controllerRef.value?.dispose();
        controllerRef.value = null;
        // drawingBoardController.pencilKitController?.dispose();
        drawingBoardController.pencilKitController = null;
        debouncer.value.dispose();
        pencilKitElement.dispose();
      };
    }, [pencilKitElement]);

    useEffect(() {
      debugPrint("[${pencilKitElement.hashCode}] enabled changed = $enabled");
      if (enabled) {
        saveTimer.addTickListener(triggerUpdate);
      } else {
        saveTimer.removeTickListener(triggerUpdate);
      }
      return () {
        debugPrint("[${pencilKitElement.hashCode}] dispose trigger update");
        saveTimer.removeTickListener(triggerUpdate);
      };
    }, [enabled]);

    return IgnorePointer(
      ignoring: !enabled,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerUp: (event) async {
                debugPrint(
                    'onPointerUp in PencilKitElement at ${event.position}');

                // wait 100ms for the drawing to finish
                await Future.delayed(const Duration(milliseconds: 100));

                if (onUpdated != null) {
                  final data = await getUpdateData(force: true);
                  if (data != null) {
                    onUpdated?.call(data);
                  }
                }
                if (onDebouncedUpdate != null) {
                  final data = await getUpdateData(force: true);
                  if (data != null) {
                    debouncer.value.run(() {
                      onDebouncedUpdate?.call(data);
                    });
                  }
                }
              },
              child: PencilKit(
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                onPencilKitViewCreated: (controller) async {
                  controllerRef.value = controller;
                  if (pencilKitElement.data != null) {
                    await controllerRef.value
                        ?.loadBase64Data(pencilKitElement.data!);
                  }
                  if (enabled) {
                    drawingBoardController.pencilKitController = controller;
                    if (drawingBoardController.drawingMode ==
                        DrawingMode.pencil) {
                      controller.show();
                    }
                  }
                },
                alwaysBounceHorizontal: false,
                alwaysBounceVertical: false,
                drawingPolicy: PencilKitIos14DrawingPolicy.anyInput,
                // onToolPickerVisibilityChanged: (isVisible) {
                //   drawingBoardController.isShowingPencilKit = isVisible;
                // },
                // onRulerActiveChanged: (isRulerActive) {
                //   debugPrint('isRulerActive $isRulerActive');
                // },
                backgroundColor: Colors.transparent,
                isOpaque: false,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DataToCheck {
  DataToCheck({
    required this.length,
    required this.firstChar,
    required this.lastChar,
  });

  final int length;
  final String firstChar;
  final String lastChar;
}
