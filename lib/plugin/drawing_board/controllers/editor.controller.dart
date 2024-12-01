import 'package:flutter/material.dart';
import 'package:makernote/plugin/drawing_board/models/graphic_element_model.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:makernote/plugin/drawing_board/services/editor_page_service.dart';
import 'package:makernote/plugin/drawing_board/util/commands/command_driver.dart';
import 'package:makernote/plugin/drawing_board/util/commands/lib/update.command.dart';
import 'package:makernote/plugin/drawing_board/util/debouncer.dart';

class EditorController extends ChangeNotifier {
  final CommandDriver driver;
  final PageModel pageModel;
  final EditorPageService editorPageService;

  GraphicElementModel? _elementRef;
  GraphicElementModel? _elementModel;
  int? _elementIndex;

  Debouncer? _debouncer;

  EditorController({
    required this.driver,
    required this.pageModel,
    required this.editorPageService,
  });

  GraphicElementModel? get elementRef => _elementRef;
  GraphicElementModel? get elementState => _elementModel;
  int? get elementIndex => _elementIndex;

  bool get hasElement =>
      _elementModel != null && _elementIndex != null && _elementRef != null;

  void setElement(GraphicElementModel element, int index) {
    _elementRef = element;
    _elementModel = element.copyWith();
    _elementIndex = index;

    _debouncer = Debouncer(milliseconds: 500);

    debugPrint('setting element: ${element.hashCode}\n'
        '\t ref: ${_elementRef.hashCode}\n'
        '\t state: ${_elementModel.hashCode}\n'
        '\t index: $_elementIndex');
    notifyListeners();
  }

  void clearElement() {
    _elementRef = null;
    _elementModel = null;
    _elementIndex = null;
    notifyListeners();
  }

  void updateStateToRef() {
    if (!hasElement) {
      return;
    }
    debugPrint('updating state to ref: ${_elementRef.hashCode}\n'
        '\t ref: ${_elementRef.hashCode}\n'
        '\t state: ${_elementModel.hashCode}\n'
        '\t index: $_elementIndex');

    _elementModel!.updateWith();
    _debouncer?.run(() {
      driver.execute(UpdateCommand(
        pageModel: pageModel,
        pageService: editorPageService,
        newElement: _elementModel!,
        elementIndex: _elementIndex!,
      ));
    });
  }

  // dispose the debouncer
  @override
  void dispose() {
    _debouncer?.dispose();
    super.dispose();
  }
}
