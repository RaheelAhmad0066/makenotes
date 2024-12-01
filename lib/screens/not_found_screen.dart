import 'package:flutter/material.dart';
import 'package:makernote/widgets/flex.extension.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FlexWithExtension.withSpacing(children: [
          Text('Error 404', style: Theme.of(context).textTheme.headlineLarge),
        ]),
      ),
    );
  }
}
