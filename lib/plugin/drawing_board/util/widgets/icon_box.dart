import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class IconBox extends HookWidget {
  final IconData? iconData;
  final Widget? child;
  final bool disabled;
  final bool selected;
  final Size size;
  final VoidCallback onTap;
  final String? tooltip;
  final BorderRadiusGeometry? borderRadius;

  const IconBox({
    super.key,
    this.iconData,
    this.child,
    this.tooltip,
    this.disabled = false,
    this.selected = false,
    this.size = const Size(40, 40),
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    required this.onTap,
  }) : assert(child != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    final isHovering = useState(false);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: AbsorbPointer(
        absorbing: disabled,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: MouseRegion(
              onEnter: (e) {
                isHovering.value = true;
              },
              onExit: (e) {
                isHovering.value = false;
              },
              child: Stack(
                children: [
                  Opacity(
                    opacity: disabled ? 0.5 : 1,
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(100)
                            : Theme.of(context).colorScheme.primary,
                        // border: Border.all(
                        //   color: selected
                        //       ? Theme.of(context).colorScheme.onSecondary
                        //       : Theme.of(context).colorScheme.secondary,
                        //   width: 1.5,
                        // ),
                        borderRadius: borderRadius,
                      ),
                      child: Center(
                        child: child ??
                            Icon(
                              iconData,
                              color: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withAlpha(100)
                                  : Theme.of(context).colorScheme.onPrimary,
                              size: size.width * 0.5,
                            ),
                      ),
                    ),
                  ),

                  // overlay
                  if (isHovering.value)
                    Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        borderRadius: borderRadius,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
