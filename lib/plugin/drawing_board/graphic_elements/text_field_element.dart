import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../controllers/editor.controller.dart';
import '../models/text_element_model.dart';
import '../util/debouncer.dart';

class TextFieldElement extends HookWidget {
  final TextElementModel textElement;

  const TextFieldElement({
    super.key,
    required this.textElement,
  });

  @override
  Widget build(BuildContext context) {
    var textController = useTextEditingController(
      text: textElement.text,
    );
    var focusNode = useFocusNode();
    var enabled = useState(false);
    final controller = Provider.of<EditorController?>(context);
    final debouncer = useRef<Debouncer>(Debouncer(milliseconds: 300));

    useEffect(() {
      return () {
        debouncer.value.dispose();
      };
    }, [debouncer]);

    return Padding(
      padding: textElement.padding,
      child: IgnorePointer(
        ignoring: (controller == null ||
            controller.elementState.hashCode != textElement.hashCode),
        child: GestureDetector(
          onTap: () {
            enabled.value = true;
            focusNode.requestFocus();
          },
          child: AbsorbPointer(
            absorbing: !enabled.value,
            child: TextField(
              focusNode: focusNode,
              controller: textController,
              maxLines: null,
              scrollPadding: EdgeInsets.zero,
              onChanged: (value) {
                textElement.updateWith(
                  text: value,
                );
                debouncer.value.run(() {
                  controller?.updateStateToRef();
                });
              },
              style: textElement.textStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                label: null,
                hintText: null,
                hintStyle: null,
                floatingLabelStyle: null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
