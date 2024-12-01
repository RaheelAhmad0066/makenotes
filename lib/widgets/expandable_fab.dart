import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ExpandableFAB extends HookWidget {
  const ExpandableFAB({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    late final AnimationController controller =
        useAnimationController(duration: const Duration(milliseconds: 250));
    late final Animation<double> animation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: controller,
    );
    final open = useState(initialOpen ?? false);

    if (open.value) {
      controller.forward();
    } else {
      controller.reverse();
    }
    return DeferredPointerHandler(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(context, onTap: () => open.value = !open.value),
          ..._buildExpandingActionButtons(
              progress: animation, children: children),
          _buildTapToOpenFab(
            open: open.value,
            onPressed: () {
              open.value = !open.value;
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons(
      {required Animation<double> progress, required List<Widget> children}) {
    final expandingChildren = <Widget>[];
    final count = children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      expandingChildren.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: distance,
          progress: progress,
          child: children[i],
        ),
      );
    }
    return expandingChildren;
  }

  Widget _buildTapToCloseFab(BuildContext context, {void Function()? onTap}) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToOpenFab(
      {required bool open, required void Function() onPressed}) {
    return IgnorePointer(
      ignoring: open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          open ? 0.7 : 1.0,
          open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: onPressed,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * pi / 2,
            child: progress.value == 1
                ? DeferPointer(
                    child: child!,
                  )
                : child,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}
