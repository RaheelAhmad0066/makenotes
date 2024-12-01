import 'package:flutter/material.dart';
import 'package:makernote/plugin/digit_recognition/draggable_widget.dart';
import 'package:makernote/plugin/digit_recognition/marking_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';

import '../../plugin/digit_recognition/drawing_widget.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('initState called in TestScreen');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          constraints: const BoxConstraints.expand(),
          // child: DraggableContainer(
          //   pageModel: PageModel(
          //     id: "1",
          //   ),
          //   defaultMarkings: [
          //     MarkingModel(
          //       pageId: "",
          //       points: [],
          //       yPosition: 0,
          //       name: "New Marking",
          //       score: 0.0,
          //     )
          //   ],
          // ),
        ),
      ),
    );
  }
}
