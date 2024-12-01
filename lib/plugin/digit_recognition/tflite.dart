import 'dart:async';
import 'package:flutter/services.dart';

class Tflite {
  static const MethodChannel _channel = MethodChannel('tflite');

  static bool _isModelLoaded = false;

  static Future<String?> loadModel(
      {required String model,
      String labels = "",
      int numThreads = 1,
      bool isAsset = true,
      bool useGpuDelegate = false}) async {
    // Close any previously loaded model before loading a new one
    // await Tflite.close();

    if (_isModelLoaded) return "Model is already loaded";

    _isModelLoaded = true;

    String? id = await _channel.invokeMethod(
      'loadModel',
      {
        "model": model,
        "labels": labels,
        "numThreads": numThreads,
        "isAsset": isAsset,
        'useGpuDelegate': useGpuDelegate
      },
    );

    if (id == null) _isModelLoaded = false;

    return id;
  }

  static Future<String?> close() async {
    if (!_isModelLoaded) return "Model is not loaded";

    _isModelLoaded = false;
    var res = await _channel.invokeMethod('close');
    return res;
  }

  static Future<List?> runModelOnImage(
      {required String path,
      double imageMean = 117.0,
      double imageStd = 1.0,
      int numResults = 5,
      double threshold = 0.1,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runModelOnImage',
      {
        "path": path,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "numResults": numResults,
        "threshold": threshold,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> runModelOnBinary(
      {required Uint8List binary,
      int numResults = 5,
      double threshold = 0.1,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runModelOnBinary',
      {
        "binary": binary,
        "numResults": numResults,
        "threshold": threshold,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> runModelOnFrame(
      {required List<Uint8List> bytesList,
      int imageHeight = 1280,
      int imageWidth = 720,
      double imageMean = 127.5,
      double imageStd = 127.5,
      int rotation = 90, // Android only
      int numResults = 5,
      double threshold = 0.1,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runModelOnFrame',
      {
        "bytesList": bytesList,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "rotation": rotation,
        "numResults": numResults,
        "threshold": threshold,
        "asynch": asynch,
      },
    );
  }

  static const anchors = [
    0.57273,
    0.677385,
    1.87446,
    2.06253,
    3.33843,
    5.47434,
    7.88282,
    3.52778,
    9.77052,
    9.16828
  ];

  static Future<List?> detectObjectOnImage({
    required String path,
    String model = "SSDMobileNet",
    double imageMean = 127.5,
    double imageStd = 127.5,
    double threshold = 0.1,
    int numResultsPerClass = 5,
    // Used in YOLO only
    List anchors = anchors,
    int blockSize = 32,
    int numBoxesPerBlock = 5,
    bool asynch = true,
  }) async {
    return await _channel.invokeMethod(
      'detectObjectOnImage',
      {
        "path": path,
        "model": model,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "threshold": threshold,
        "numResultsPerClass": numResultsPerClass,
        "anchors": anchors,
        "blockSize": blockSize,
        "numBoxesPerBlock": numBoxesPerBlock,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> detectObjectOnBinary({
    required Uint8List binary,
    String model = "SSDMobileNet",
    double threshold = 0.1,
    int numResultsPerClass = 5,
    // Used in YOLO only
    List anchors = anchors,
    int blockSize = 32,
    int numBoxesPerBlock = 5,
    bool asynch = true,
  }) async {
    return await _channel.invokeMethod(
      'detectObjectOnBinary',
      {
        "binary": binary,
        "model": model,
        "threshold": threshold,
        "numResultsPerClass": numResultsPerClass,
        "anchors": anchors,
        "blockSize": blockSize,
        "numBoxesPerBlock": numBoxesPerBlock,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> detectObjectOnFrame({
    required List<Uint8List> bytesList,
    String model = "SSDMobileNet",
    int imageHeight = 1280,
    int imageWidth = 720,
    double imageMean = 127.5,
    double imageStd = 127.5,
    double threshold = 0.1,
    int numResultsPerClass = 5,
    int rotation = 90, // Android only
    // Used in YOLO only
    List anchors = anchors,
    int blockSize = 32,
    int numBoxesPerBlock = 5,
    bool asynch = true,
  }) async {
    return await _channel.invokeMethod(
      'detectObjectOnFrame',
      {
        "bytesList": bytesList,
        "model": model,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "rotation": rotation,
        "threshold": threshold,
        "numResultsPerClass": numResultsPerClass,
        "anchors": anchors,
        "blockSize": blockSize,
        "numBoxesPerBlock": numBoxesPerBlock,
        "asynch": asynch,
      },
    );
  }

  static Future<Uint8List?> runPix2PixOnImage(
      {required String path,
      double imageMean = 0,
      double imageStd = 255.0,
      String outputType = "png",
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runPix2PixOnImage',
      {
        "path": path,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "asynch": asynch,
        "outputType": outputType,
      },
    );
  }

  static Future<Uint8List?> runPix2PixOnBinary(
      {required Uint8List binary,
      String outputType = "png",
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runPix2PixOnBinary',
      {
        "binary": binary,
        "asynch": asynch,
        "outputType": outputType,
      },
    );
  }

  static Future<Uint8List?> runPix2PixOnFrame({
    required List<Uint8List> bytesList,
    int imageHeight = 1280,
    int imageWidth = 720,
    double imageMean = 0,
    double imageStd = 255.0,
    int rotation = 90, // Android only
    String outputType = "png",
    bool asynch = true,
  }) async {
    return await _channel.invokeMethod(
      'runPix2PixOnFrame',
      {
        "bytesList": bytesList,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "rotation": rotation,
        "asynch": asynch,
        "outputType": outputType,
      },
    );
  }

  // https://github.com/meetshah1995/pytorch-semseg/blob/master/ptsemseg/loader/pascal_voc_loader.py
  static List<int> pascalVOCLabelColors = [
    const Color.fromARGB(255, 0, 0, 0).value, // background
    const Color.fromARGB(255, 128, 0, 0).value, // aeroplane
    const Color.fromARGB(255, 0, 128, 0).value, // biyclce
    const Color.fromARGB(255, 128, 128, 0).value, // bird
    const Color.fromARGB(255, 0, 0, 128).value, // boat
    const Color.fromARGB(255, 128, 0, 128).value, // bottle
    const Color.fromARGB(255, 0, 128, 128).value, // bus
    const Color.fromARGB(255, 128, 128, 128).value, // car
    const Color.fromARGB(255, 64, 0, 0).value, // cat
    const Color.fromARGB(255, 192, 0, 0).value, // chair
    const Color.fromARGB(255, 64, 128, 0).value, // cow
    const Color.fromARGB(255, 192, 128, 0).value, // diningtable
    const Color.fromARGB(255, 64, 0, 128).value, // dog
    const Color.fromARGB(255, 192, 0, 128).value, // horse
    const Color.fromARGB(255, 64, 128, 128).value, // motorbike
    const Color.fromARGB(255, 192, 128, 128).value, // person
    const Color.fromARGB(255, 0, 64, 0).value, // potted plant
    const Color.fromARGB(255, 128, 64, 0).value, // sheep
    const Color.fromARGB(255, 0, 192, 0).value, // sofa
    const Color.fromARGB(255, 128, 192, 0).value, // train
    const Color.fromARGB(255, 0, 64, 128).value, // tv-monitor
  ];

  static Future<Uint8List?> runSegmentationOnImage(
      {required String path,
      double imageMean = 0,
      double imageStd = 255.0,
      List<int>? labelColors,
      String outputType = "png",
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runSegmentationOnImage',
      {
        "path": path,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "labelColors": labelColors ?? pascalVOCLabelColors,
        "outputType": outputType,
        "asynch": asynch,
      },
    );
  }

  static Future<Uint8List?> runSegmentationOnBinary(
      {required Uint8List binary,
      List<int>? labelColors,
      String outputType = "png",
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runSegmentationOnBinary',
      {
        "binary": binary,
        "labelColors": labelColors ?? pascalVOCLabelColors,
        "outputType": outputType,
        "asynch": asynch,
      },
    );
  }

  static Future<Uint8List?> runSegmentationOnFrame(
      {required List<Uint8List> bytesList,
      int imageHeight = 1280,
      int imageWidth = 720,
      double imageMean = 0,
      double imageStd = 255.0,
      int rotation = 90, // Android only
      List<int>? labelColors,
      String outputType = "png",
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runSegmentationOnFrame',
      {
        "bytesList": bytesList,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "rotation": rotation,
        "labelColors": labelColors ?? pascalVOCLabelColors,
        "outputType": outputType,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> runPoseNetOnImage(
      {required String path,
      double imageMean = 127.5,
      double imageStd = 127.5,
      int numResults = 5,
      double threshold = 0.5,
      int nmsRadius = 20,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runPoseNetOnImage',
      {
        "path": path,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "numResults": numResults,
        "threshold": threshold,
        "nmsRadius": nmsRadius,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> runPoseNetOnBinary(
      {required Uint8List binary,
      int numResults = 5,
      double threshold = 0.5,
      int nmsRadius = 20,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runPoseNetOnBinary',
      {
        "binary": binary,
        "numResults": numResults,
        "threshold": threshold,
        "nmsRadius": nmsRadius,
        "asynch": asynch,
      },
    );
  }

  static Future<List?> runPoseNetOnFrame(
      {required List<Uint8List> bytesList,
      int imageHeight = 1280,
      int imageWidth = 720,
      double imageMean = 127.5,
      double imageStd = 127.5,
      int rotation = 90, // Android only
      int numResults = 5,
      double threshold = 0.5,
      int nmsRadius = 20,
      bool asynch = true}) async {
    return await _channel.invokeMethod(
      'runPoseNetOnFrame',
      {
        "bytesList": bytesList,
        "imageHeight": imageHeight,
        "imageWidth": imageWidth,
        "imageMean": imageMean,
        "imageStd": imageStd,
        "rotation": rotation,
        "numResults": numResults,
        "threshold": threshold,
        "nmsRadius": nmsRadius,
        "asynch": asynch,
      },
    );
  }
}