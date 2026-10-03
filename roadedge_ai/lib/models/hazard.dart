import 'dart:convert';
import 'detection.dart';

/// Local Hazard Entity for on-device persistence and Municipal Intelligence export
class Hazard {
  final String id;
  final String type;
  final double confidence;
  final String severity;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double distance;
  final String source; // "EDGE_NNAPI", "EDGE_CPU", "SIMULATED_ENGINE"
  final String status; // "LOGGED", "VERIFIED", "MUNICIPAL_DISPATCHED", "RESOLVED"
  final String roadName;

  Hazard({
    required this.id,
    required this.type,
    required this.confidence,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.distance,
    this.source = 'EDGE_MODEL_INT8',
    this.status = 'LOGGED',
    this.roadName = 'Smart Road Corridor',
  });

  /// Factory from a live Detection object + GPS fix
  factory Hazard.fromDetection({
    required Detection detection,
    required double latitude,
    required double longitude,
    String source = 'EDGE_MODEL_INT8',
    String roadName = 'Cyber Corridor Expressway',
  }) {
    return Hazard(
      id: 'HAZ-${DateTime.now().millisecondsSinceEpoch}-${detection.type.name.toUpperCase().substring(0, 3)}',
      type: detection.type.displayName,
      confidence: detection.confidence,
      severity: detection.severity.displayName,
      latitude: latitude,
      longitude: longitude,
      timestamp: detection.timestamp,
      distance: detection.distanceMeters,
      source: source,
      status: 'LOGGED',
      roadName: roadName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'confidence': confidence,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'distance': distance,
      'source': source,
      'status': status,
      'roadName': roadName,
    };
  }

  factory Hazard.fromMap(Map<String, dynamic> map) {
    return Hazard(
      id: map['id'] ?? '',
      type: map['type'] ?? 'UNKNOWN',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: map['severity'] ?? 'LOW',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      source: map['source'] ?? 'EDGE_MODEL_INT8',
      status: map['status'] ?? 'LOGGED',
      roadName: map['roadName'] ?? 'Urban Arterial Way',
    );
  }

  String toJson() => json.encode(toMap());

  factory Hazard.fromJson(String source) => Hazard.fromMap(json.decode(source));

  /// Convert to GeoJSON Feature representation
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // GeoJSON standard: [lon, lat]
      },
      'properties': {
        'id': id,
        'hazard_type': type,
        'severity': severity,
        'confidence_score': (confidence * 100).round(),
        'distance_at_detection_meters': distance,
        'detection_source': source,
        'status': status,
        'road_segment': roadName,
        'detected_at': timestamp.toIso8601String(),
        'on_device_verified': true,
      },
    };
  }
}
