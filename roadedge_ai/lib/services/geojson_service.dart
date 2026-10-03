import 'dart:convert';
import '../models/hazard.dart';

/// GeoJSON Service for Municipal Road Safety & Highway Authority Integration
/// Generates RFC 7946 compliant GeoJSON FeatureCollections for GIS & Smart City systems.
class GeoJsonService {
  /// Generate standard FeatureCollection from stored hazards
  static Map<String, dynamic> generateFeatureCollection(List<Hazard> hazards) {
    return {
      'type': 'FeatureCollection',
      'generator': 'RoadEdge AI On-Device Vision Engine v1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'bbox': _calculateBBox(hazards),
      'metadata': {
        'total_hazards': hazards.length,
        'critical_count': hazards.where((h) => h.severity == 'CRITICAL').length,
        'high_count': hazards.where((h) => h.severity == 'HIGH').length,
        'medium_count': hazards.where((h) => h.severity == 'MEDIUM').length,
        'low_count': hazards.where((h) => h.severity == 'LOW').length,
        'export_scope': 'Municipal Highway Intelligence',
      },
      'features': hazards.map((h) => h.toGeoJsonFeature()).toList(),
    };
  }

  /// Generate pretty formatted JSON string
  static String exportGeoJsonString(List<Hazard> hazards, {bool pretty = true}) {
    final collection = generateFeatureCollection(hazards);
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(collection);
    }
    return json.encode(collection);
  }

  /// Calculate bounding box [minLon, minLat, maxLon, maxLat]
  static List<double> _calculateBBox(List<Hazard> hazards) {
    if (hazards.isEmpty) return [0.0, 0.0, 0.0, 0.0];

    double minLat = hazards.first.latitude;
    double maxLat = hazards.first.latitude;
    double minLon = hazards.first.longitude;
    double maxLon = hazards.first.longitude;

    for (final h in hazards) {
      if (h.latitude < minLat) minLat = h.latitude;
      if (h.latitude > maxLat) maxLat = h.latitude;
      if (h.longitude < minLon) minLon = h.longitude;
      if (h.longitude > maxLon) maxLon = h.longitude;
    }

    return [minLon, minLat, maxLon, maxLat];
  }
}
