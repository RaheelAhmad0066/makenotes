import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.withText,
    this.size,
  });

  final bool? withText;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          clipBehavior: Clip.antiAlias,
          constraints:
              BoxConstraints(maxHeight: size ?? 40, maxWidth: size ?? 40),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (withText == true) const Text('Makernote'),
      ],
    );
  }
}
