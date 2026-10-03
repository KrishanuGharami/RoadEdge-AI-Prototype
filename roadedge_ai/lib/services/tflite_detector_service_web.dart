import '../models/detection.dart';
import '../utils/constants.dart';
import 'detector_service.dart';
import 'simulated_detector_service.dart';

/// Web fallback detector service for RoadEdge AI
/// Provides simulated Edge AI inference and Web-compatible diagnostics
/// without native C/C++ FFI or tensorflow_lite binary bindings.
class TfliteDetectorService implements DetectorService {
  final SimulatedDetectorService _simulatedFallback = SimulatedDetectorService();

  @override
  bool get isModelLoaded => true;

  @override
  String get backendName => 'Web Edge Fallback (WASM / WebGL)';

  @override
  String get accelerationInfo => 'WebGL / WebAssembly Edge Runtime (Cross-Browser)';

  @override
  String get runtimeEngine => 'LiteRT Web Runtime';

  @override
  String get modelArchitecture => AppConstants.targetModelName;

  @override
  double get confidenceThreshold => _simulatedFallback.confidenceThreshold;

  @override
  set confidenceThreshold(double value) {
    _simulatedFallback.confidenceThreshold = value;
  }

  @override
  double get iouThreshold => _simulatedFallback.iouThreshold;

  @override
  set iouThreshold(double value) {
    _simulatedFallback.iouThreshold = value;
  }

  @override
  Future<void> initialize() async {
    await _simulatedFallback.initialize();
  }

  @override
  Future<List<Detection>> detect(dynamic frame) async {
    return _simulatedFallback.detect(frame);
  }

  @override
  void dispose() {
    _simulatedFallback.dispose();
  }
}
