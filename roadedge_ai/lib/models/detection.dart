import 'package:flutter/material.dart';

enum HazardType {
  pothole,
  roadCrack,
  obstacle,
  pedestrian,
  vehicle,
  debris;

  String get displayName {
    switch (this) {
      case HazardType.pothole:
        return 'POTHOLE';
      case HazardType.roadCrack:
        return 'ROAD CRACK';
      case HazardType.obstacle:
        return 'OBSTACLE';
      case HazardType.pedestrian:
        return 'PEDESTRIAN';
      case HazardType.vehicle:
        return 'VEHICLE';
      case HazardType.debris:
        return 'DEBRIS';
    }
  }

  static HazardType fromString(String val) {
    final v = val.toUpperCase().replaceAll(' ', '_');
    for (final type in HazardType.values) {
      if (type.name.toUpperCase() == v || type.displayName.replaceAll(' ', '_') == v) {
        return type;
      }
    }
    return HazardType.obstacle;
  }
}

enum HazardSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case HazardSeverity.low:
        return 'LOW';
      case HazardSeverity.medium:
        return 'MEDIUM';
      case HazardSeverity.high:
        return 'HIGH';
      case HazardSeverity.critical:
        return 'CRITICAL';
    }
  }

  static HazardSeverity fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CRITICAL':
        return HazardSeverity.critical;
      case 'HIGH':
        return HazardSeverity.high;
      case 'MEDIUM':
        return HazardSeverity.medium;
      case 'LOW':
      default:
        return HazardSeverity.low;
    }
  }
}

class BoundingBox {
  final double left;   // Normalized [0..1]
  final double top;    // Normalized [0..1]
  final double width;  // Normalized [0..1]
  final double height; // Normalized [0..1]

  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Rect toRect(Size screenSize) {
    return Rect.fromLTWH(
      left * screenSize.width,
      top * screenSize.height,
      width * screenSize.width,
      height * screenSize.height,
    );
  }

  double get area => width * height;
}

class Detection {
  final String id;
  final HazardType type;
  final double confidence; // [0.0 .. 1.0]
  final BoundingBox boundingBox;
  final double distanceMeters;
  final HazardSeverity severity;
  final DateTime timestamp;

  Detection({
    required this.id,
    required this.type,
    required this.confidence,
    required this.boundingBox,
    required this.distanceMeters,
    required this.severity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get label => type.displayName;
  int get confidencePercent => (confidence * 100).round();
  String get distanceDisplay => '${distanceMeters.toStringAsFixed(0)} meters ahead';
}
