import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/helpers/file_picker.helper.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

class NoteCreateFromPDFDialog extends HookWidget {
  NoteCreateFromPDFDialog({
    super.key,
    required this.type,
    this.folderId,
  });

  final ItemType type;
  final String? folderId;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final pdfDocument = useState<Future<PdfDocument>?>(null);
    final pdfController = useMemoized(() {
      if (pdfDocument.value != null) {
        return PdfControllerPinch(document: pdfDocument.value!);
      } else {
        return null;
      }
    }, [pdfDocument.value]);

    final createFormKey = useMemoized(() => GlobalKey<FormState>());
    final textEditingController = useTextEditingController();

    final loadingState = useState(false);

    // UseEffect to ensure resources are disposed properly
    useEffect(() {
      return () {
        // Dispose the controller if it's not null
        pdfController?.dispose();
      };
    }, []);

    return AlertDialog(
      title: Text('Create a new ${type.toString().split('.').last}'),
      // pdf file picker
      content: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: pdfController == null
            ? PDFFilePicker(
                onFilePicked: (data) {
                  pdfDocument.value = PdfDocument.openData(data);
                },
              )
            : SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Scaffold(
                  appBar: AppBar(
                    toolbarHeight: kToolbarHeight * 1.5,
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Form(
                      key: createFormKey,
                      child: TextFormField(
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          hintText: 'Please enter a name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                    ),
                    actions: [
                      // preview page button
                      IconButton(
                        onPressed: () async {
                          pdfController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),

                      // next page button
                      IconButton(
                        onPressed: () async {
                          pdfController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),

                      // remove pdf button
                      IconButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          pdfDocument.value = null;
                          pdfController.dispose();
                        },
                        icon: const Icon(Icons.delete),
                      )
                    ],
                  ),
                  body: Stack(
                    children: [
                      PdfViewPinch(
                        controller: pdfController,
                        onDocumentLoaded: (document) {},
                        onPageChanged: (page) {},
                        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                          options: const DefaultBuilderOptions(),
                          documentLoaderBuilder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          pageLoaderBuilder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                          errorBuilder: (_, error) =>
                              Center(child: Text(error.toString())),
                        ),
                      ),

                      // loading overlay
                      if (loadingState.value)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        // cancel button with neutral color
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).hintColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: !loadingState.value && pdfController != null
              ? () async {
                  String? newItemId;
                  if (createFormKey.currentState!.validate()) {
                    try {
                      loadingState.value = true;
                      final noteService =
                          Provider.of<NoteService>(context, listen: false);
                      newItemId = await noteService.createFromPdf(
                        name: textEditingController.text,
                        parentId: folderId,
                        pdfDocument: await pdfDocument.value,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Note created'),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error creating note: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating note: $e'),
                          ),
                        );
                      }
                    } finally {
                      loadingState.value = false;
                    }
                    if (context.mounted) Navigator.pop(context, newItemId);
                  } else {}
                }
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class PDFFilePicker extends HookWidget {
  const PDFFilePicker({
    super.key,
    required this.onFilePicked,
  });

  final Function(FutureOr<Uint8List>) onFilePicked;

  @override
  Widget build(BuildContext context) {
    // click to pick file
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: () async {
            try {
              final file = await pickFile(allowedExtensions: ['pdf']);
              if (file != null) {
                debugPrint('PDF picked: ${file.length}');
                onFilePicked(file);
              } else {
                debugPrint('No PDF selected');
              }
            } catch (e) {
              debugPrint('Error picking PDF: $e');
              rethrow;
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_upload),
                SizedBox(height: 8),
                Text('Click to pick a PDF file'),
              ],
            ),
          )),
    );
  }
}
