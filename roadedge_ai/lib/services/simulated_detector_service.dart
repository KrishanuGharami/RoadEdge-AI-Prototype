import '../models/detection.dart';
import 'detector_service.dart';
import 'risk_engine.dart';

/// Simulated Edge AI Detection Engine
/// Faithfully reproduces the required hackathon demo detection sequence
/// with animated bounding box kinematics, realistic distances, and confidence ratings.
class SimulatedDetectorService implements DetectorService {
  double _confidenceThreshold = 0.60;
  double _iouThreshold = 0.45;
  bool _isInitialized = false;

  // Manual override hazard if requested during pitch
  HazardType? _manualOverrideType;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  bool get isModelLoaded => true;

  @override
  String get backendName => 'NNAPI / Qualcomm Hexagon NPU (Simulated)';

  @override
  String get accelerationInfo => 'Qualcomm NPU Compatible • Zero Latency Fallback';

  @override
  String get runtimeEngine => 'LiteRT / TFLite Edge Runtime';

  @override
  String get modelArchitecture => 'YOLOv8n-RoadHazard INT8 (640x640)';

  @override
  double get confidenceThreshold => _confidenceThreshold;

  @override
  set confidenceThreshold(double value) => _confidenceThreshold = value;

  @override
  double get iouThreshold => _iouThreshold;

  @override
  set iouThreshold(double value) => _iouThreshold = value;

  void triggerManualHazard(HazardType type) {
    _manualOverrideType = type;
  }

  void clearManualHazard() {
    _manualOverrideType = null;
  }

  /// Generate detections based on current driving timestamp / cycle position (in seconds)
  List<Detection> getDetectionsForCycleTime(double secondsInCycle) {
    if (!_isInitialized) return [];

    // Check manual override first
    if (_manualOverrideType != null) {
      return [_buildDetectionForType(_manualOverrideType!, 15.0, 0.93)];
    }

    final cycle = secondsInCycle % 28.0;

    // 0 - 5 sec: Clear road / scanning
    if (cycle < 5.0) {
      return [];
    }
    // 5 - 9 sec: Road crack detected (Conf 87%, Severity MEDIUM)
    else if (cycle < 9.0) {
      final progress = (cycle - 5.0) / 4.0; // 0.0 to 1.0
      final distance = 25.0 - (progress * 13.0); // 25m down to 12m
      final top = 0.50 + (progress * 0.18);
      final left = 0.42 - (progress * 0.05);
      final width = 0.22 + (progress * 0.12);
      final height = 0.10 + (progress * 0.08);

      final det = Detection(
        id: 'SIM-CRACK',
        type: HazardType.roadCrack,
        confidence: 0.87,
        boundingBox: BoundingBox(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
        distanceMeters: distance,
        severity: HazardSeverity.medium,
      );
      return [det];
    }
    // 9 - 14 sec: Pothole detected (Conf 94%, Severity HIGH)
    else if (cycle < 14.0) {
      final progress = (cycle - 9.0) / 5.0;
      final distance = 22.0 - (progress * 14.0); // 22m down to 8m
      final top = 0.52 + (progress * 0.22);
      final left = 0.48 - (progress * 0.04);
      final width = 0.18 + (progress * 0.16);
      final height = 0.12 + (progress * 0.12);

      final det = Detection(
        id: 'SIM-POTHOLE',
        type: HazardType.pothole,
        confidence: 0.94,
        boundingBox: BoundingBox(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
        distanceMeters: distance,
        severity: distance < 12 ? HazardSeverity.high : HazardSeverity.medium,
      );
      return [det];
    }
    // 14 - 18 sec: Pedestrian detected (Conf 91%, Severity CRITICAL)
    else if (cycle < 18.0) {
      final progress = (cycle - 14.0) / 4.0;
      final distance = 26.0 - (progress * 16.0); // 26m down to 10m
      final top = 0.38 + (progress * 0.12);
      final left = 0.58 - (progress * 0.08); // approaching right shoulder/lane
      final width = 0.12 + (progress * 0.10);
      final height = 0.28 + (progress * 0.18);

      final det = Detection(
        id: 'SIM-PEDESTRIAN',
        type: HazardType.pedestrian,
        confidence: 0.91,
        boundingBox: BoundingBox(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
        distanceMeters: distance,
        severity: HazardSeverity.critical,
      );
      return [det];
    }
    // 18 - 23 sec: Obstacle detected (Conf 89%, Severity HIGH)
    else if (cycle < 23.0) {
      final progress = (cycle - 18.0) / 5.0;
      final distance = 20.0 - (progress * 13.0); // 20m down to 7m
      final top = 0.50 + (progress * 0.18);
      final left = 0.34 - (progress * 0.06);
      final width = 0.16 + (progress * 0.14);
      final height = 0.15 + (progress * 0.12);

      final det = Detection(
        id: 'SIM-OBSTACLE',
        type: HazardType.obstacle,
        confidence: 0.89,
        boundingBox: BoundingBox(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
        distanceMeters: distance,
        severity: HazardSeverity.high,
      );
      return [det];
    }
    // 23 - 28 sec: Debris detected (Conf 84%, Severity MEDIUM)
    else {
      final progress = (cycle - 23.0) / 5.0;
      final distance = 24.0 - (progress * 14.0);
      final top = 0.55 + (progress * 0.18);
      final left = 0.44 + (progress * 0.05);
      final width = 0.14 + (progress * 0.12);
      final height = 0.09 + (progress * 0.08);

      final det = Detection(
        id: 'SIM-DEBRIS',
        type: HazardType.debris,
        confidence: 0.84,
        boundingBox: BoundingBox(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
        distanceMeters: distance,
        severity: HazardSeverity.medium,
      );
      return [det];
    }
  }

  Detection _buildDetectionForType(HazardType type, double dist, double conf) {
    return Detection(
      id: 'MANUAL-${type.name}',
      type: type,
      confidence: conf,
      boundingBox: const BoundingBox(
        left: 0.35,
        top: 0.45,
        width: 0.30,
        height: 0.30,
      ),
      distanceMeters: dist,
      severity: RiskEngine.evaluate(
        type: type,
        confidence: conf,
        distanceMeters: dist,
        normalizedArea: 0.09,
        lateralOffsetFromCenter: 0.0,
      ),
    );
  }

  @override
  Future<List<Detection>> detect(dynamic frame) async {
    // Used when running in simulated mode
    return getDetectionsForCycleTime(DateTime.now().second.toDouble());
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
