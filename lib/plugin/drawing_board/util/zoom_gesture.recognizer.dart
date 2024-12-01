import 'package:flutter/gestures.dart';

class TwoFingerZoomGestureRecognizer extends ScaleGestureRecognizer {
  TwoFingerZoomGestureRecognizer();

  @override
  void addAllowedPointer(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus) {
      // Accept the gesture only if the pointer is not a stylus
      super.addAllowedPointer(event as PointerDownEvent);
    }
  }

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
