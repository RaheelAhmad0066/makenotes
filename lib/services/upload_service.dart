import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

enum FileType {
  image,
  video,
}

class UploadService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<XFile> pickMedia(FileType fileType,
      {ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    try {
      final pickedFile = fileType == FileType.image
          ? await picker.pickImage(source: source)
          : await picker.pickVideo(source: source);
      if (pickedFile == null) throw Exception('Media not found');
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking media: $e');
      rethrow;
    }
  }

  Uint8List compressImage(File file) {
    final originalImage = img.decodeImage(file.readAsBytesSync())!;
    final compressedImage = img.copyResize(originalImage, width: 600);
    return Uint8List.fromList(img.encodeJpg(compressedImage, quality: 85));
  }

  Future<String> uploadFile({
    required FileType fileType,
    String? prefix,
    ImageSource source = ImageSource.gallery,
  }) async {
    final userId = getUserId();
    late final XFile pickedFile;

    pickedFile = await pickMedia(fileType, source: source);

    String fileName;
    SettableMetadata? metadata;
    Uint8List data;
    Reference ref;

    if (kIsWeb) {
      // Web
      fileName = pickedFile.name;
      metadata = SettableMetadata(contentType: pickedFile.mimeType);
      data = await pickedFile.readAsBytes();
    } else {
      // Mobile
      fileName = pickedFile.path.split('/').last;
      String contentType =
          fileType == FileType.image ? 'image/jpeg' : 'video/mp4';
      metadata = SettableMetadata(contentType: contentType);
      File file = File(pickedFile.path);
      data = fileType == FileType.image
          ? compressImage(file)
          : await file.readAsBytes();
    }

    // add a time based suffix to the file name
    fileName =
        '${fileName.split('.').first}-${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';

    if (prefix != null) {
      fileName = '$prefix/$fileName';
    }

    ref = storage.ref().child('$userId/private/$fileName');

    debugPrint("File Name: $fileName");
    debugPrint("User ID: $userId");
    try {
      await ref.putData(data, metadata);

      // remove the bytes from memory
      data = Uint8List(0);
    } catch (e) {
      debugPrint("Upload Error: $e");

      // remove the bytes from memory
      data = Uint8List(0);
      rethrow;
    }

    return await ref.getDownloadURL();
  }

  Future<String> uploadImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    String? prefix,
  }) async {
    try {
      SettableMetadata? metadata;
      Uint8List data = imageBytes;
      final userId = getUserId();

      // add a time based suffix to the file name
      fileName =
          '${fileName.split('.').first}-${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';

      if (prefix != null) {
        fileName = '$prefix/$fileName';
      }

      final ref = storage.ref().child('$userId/private/$fileName');

      metadata = SettableMetadata(contentType: 'image/png');

      await ref.putData(data, metadata);

      // remove the bytes from memory
      data = Uint8List(0);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Error: $e");
      rethrow;
    }
  }
}
