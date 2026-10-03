/// RoadEdge AI - Global App Constants & Hardware Specifications
class AppConstants {
  static const String appName = 'ROAD EDGE AI';
  static const String appTagline = 'On-device intelligence for safer roads';
  static const String appSubtitle = 'Edge Intelligence for Safer Roads';
  static const String hackathonTrack = 'NAVONMESH \'26 • Track PS-02: Intelligent Road Hazard Detection';

  // Target Model Specs (YOLOv8n / YOLO11n Nano INT8)
  static const String targetModelName = 'YOLOv8n-RoadHazard INT8';
  static const String modelAssetPath = 'assets/models/road_hazard_int8.tflite';
  static const int modelInputSize = 640;
  static const double defaultConfidenceThreshold = 0.60;
  static const double defaultIouThreshold = 0.45;
  static const String targetLatency = '<25 ms';
  static const String accelerationHardware = 'Qualcomm Hexagon NPU / NNAPI compatible';
  static const String runtimeEngine = 'LiteRT / TFLite Edge Runtime';

  // Supported Hazard Detection Classes
  static const List<String> supportedClasses = [
    'POTHOLE',
    'ROAD CRACK',
    'OBSTACLE',
    'PEDESTRIAN',
    'VEHICLE',
    'DEBRIS',
  ];

  // Severity Tiers
  static const String severityLow = 'LOW';
  static const String severityMedium = 'MEDIUM';
  static const String severityHigh = 'HIGH';
  static const String severityCritical = 'CRITICAL';

  // Default Smart City Corridor Coordinates (NAVONMESH 2026 Demo GPS Seed)
  static const double defaultLatitude = 28.6139;
  static const double defaultLongitude = 77.2090;
  static const String defaultRoadName = 'National Highway 48 - Cyber Corridor';

  // Alert Cooldown (ms)
  static const int alertCooldownMs = 3500;
}
