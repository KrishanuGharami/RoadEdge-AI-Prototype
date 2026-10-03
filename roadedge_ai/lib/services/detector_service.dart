import '../models/detection.dart';

/// Abstract Detector Service specification for Edge AI Inference
abstract class DetectorService {
  Future<void> initialize();
  Future<List<Detection>> detect(dynamic frame);
  void dispose();

  bool get isModelLoaded;
  String get backendName;
  String get accelerationInfo;
  String get runtimeEngine;
  String get modelArchitecture;
  double get confidenceThreshold;
  set confidenceThreshold(double value);
  double get iouThreshold;
  set iouThreshold(double value);
}
