import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:makernote/services/upload_service.dart';

class PickFileDialog extends HookWidget {
  const PickFileDialog({
    super.key,
    required this.fileType,
    this.onSuccess,
    this.prefix,
  });

  final FileType fileType;
  final String? prefix;

  final void Function(String)? onSuccess;

  @override
  Widget build(BuildContext context) {
    final loading = useState(false);
    return Stack(
      children: [
        AlertDialog(
          title: Text("Pick ${fileType.name}"),
          content: Text(
              "Pick a ${fileType.name} from your device or from the camera."),
          actions: [
            TextButton.icon(
              onPressed: () async {
                loading.value = true;
                UploadService uploadService = UploadService();
                try {
                  final url = await uploadService.uploadFile(
                    fileType: fileType,
                    source: ImageSource.camera,
                    prefix: prefix,
                  );
                  onSuccess?.call(url);
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          title: Text("System Error"),
                          content: Text(
                              "Please goto device \"Settings > Makernote\" to allow Photos access"),
                        );
                      },
                    );
                  }
                } finally {
                  loading.value = false;
                }
              },
              label: const Text("Camera"),
              icon: const Icon(Icons.camera_alt),
            ),

            TextButton.icon(
              onPressed: () async {
                loading.value = true;
                UploadService uploadService = UploadService();
                try {
                  final url = await uploadService.uploadFile(
                    fileType: fileType,
                    source: ImageSource.gallery,
                    prefix: prefix,
                  );
                  onSuccess?.call(url);
                } finally {
                  loading.value = false;
                }
              },
              label: const Text("Device"),
              icon: const Icon(Icons.folder),
            ),

            // cancel button
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).hintColor,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
        if (loading.value)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
