import '../models/detection.dart';

/// Intelligent Risk Engine for RoadEdge AI
/// Evaluates object class, detection confidence, estimated distance,
/// bounding box geometry/area, and lateral lane position to produce
/// a deterministic severity rating: LOW, MEDIUM, HIGH, CRITICAL.
class RiskEngine {
  /// Calculate risk from a Detection instance
  static HazardSeverity calculateRisk(Detection detection) {
    return evaluate(
      type: detection.type,
      confidence: detection.confidence,
      distanceMeters: detection.distanceMeters,
      normalizedArea: detection.boundingBox.area,
      lateralOffsetFromCenter: (detection.boundingBox.left + detection.boundingBox.width / 2) - 0.5,
    );
  }

  /// Comprehensive multi-variable risk evaluation
  static HazardSeverity evaluate({
    required HazardType type,
    required double confidence,
    required double distanceMeters,
    required double normalizedArea,
    required double lateralOffsetFromCenter, // -0.5 (far left) to +0.5 (far right)
  }) {
    // Is the object directly in our immediate driving lane?
    final bool isInDrivingLane = lateralOffsetFromCenter.abs() < 0.22;

    switch (type) {
      case HazardType.pedestrian:
        // Vulnerable road users are highest priority
        if (distanceMeters <= 25.0) {
          return HazardSeverity.critical;
        } else if (distanceMeters <= 40.0 && isInDrivingLane) {
          return HazardSeverity.critical;
        } else if (distanceMeters <= 50.0) {
          return HazardSeverity.high;
        }
        return HazardSeverity.medium;

      case HazardType.pothole:
        // Dangerous to vehicle suspension & stability
        if (distanceMeters <= 12.0 && isInDrivingLane) {
          return HazardSeverity.critical;
        } else if (distanceMeters <= 22.0 && confidence >= 0.75) {
          return HazardSeverity.high;
        } else if (distanceMeters <= 35.0 || normalizedArea > 0.05) {
          return HazardSeverity.medium;
        }
        return HazardSeverity.low;

      case HazardType.obstacle:
        // Physical blockage on road
        if (distanceMeters <= 15.0 && isInDrivingLane) {
          return HazardSeverity.critical;
        } else if (distanceMeters <= 25.0) {
          return HazardSeverity.high;
        }
        return HazardSeverity.medium;

      case HazardType.roadCrack:
        // Surface degradation
        if (distanceMeters <= 10.0 && normalizedArea > 0.08) {
          return HazardSeverity.high;
        } else if (distanceMeters <= 25.0) {
          return HazardSeverity.medium;
        }
        return HazardSeverity.low;

      case HazardType.debris:
        // Loose objects, tire shreds, rocks
        if (distanceMeters <= 12.0 && isInDrivingLane) {
          return HazardSeverity.high;
        } else if (distanceMeters <= 25.0) {
          return HazardSeverity.medium;
        }
        return HazardSeverity.low;

      case HazardType.vehicle:
        // Lead vehicle or stopped vehicle ahead
        if (distanceMeters <= 8.0) {
          return HazardSeverity.critical;
        } else if (distanceMeters <= 18.0) {
          return HazardSeverity.high;
        } else if (distanceMeters <= 35.0) {
          return HazardSeverity.medium;
        }
        return HazardSeverity.low;
    }
  }

  /// Synthesize a natural human-readable driver advisory voice phrase
  static String generateVoiceAlert(Detection detection) {
    final typeName = detection.type.displayName.toLowerCase();
    final dist = detection.distanceMeters.round();

    switch (detection.severity) {
      case HazardSeverity.critical:
        if (detection.type == HazardType.pedestrian) {
          return 'Pedestrian ahead! Please brake immediately.';
        }
        return 'Warning! Critical $typeName $dist meters ahead.';
      case HazardSeverity.high:
        return '$typeName $dist meters ahead.';
      case HazardSeverity.medium:
        return 'Caution, $typeName detected ahead.';
      case HazardSeverity.low:
        return '$typeName noted ahead.';
    }
  }
}
