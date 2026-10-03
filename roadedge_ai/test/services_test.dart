import 'package:flutter_test/flutter_test.dart';
import 'package:roadedge_ai/models/detection.dart';
import 'package:roadedge_ai/models/hazard.dart';
import 'package:roadedge_ai/services/geojson_service.dart';
import 'package:roadedge_ai/services/risk_engine.dart';
import 'package:roadedge_ai/services/simulated_detector_service.dart';

void main() {
  group('RiskEngine Safety Evaluation Tests', () {
    test('Close pedestrian yields CRITICAL severity', () {
      final severity = RiskEngine.evaluate(
        type: HazardType.pedestrian,
        confidence: 0.92,
        distanceMeters: 18.0,
        normalizedArea: 0.08,
        lateralOffsetFromCenter: 0.05,
      );
      expect(severity, HazardSeverity.critical);
    });

    test('Immediate lane pothole yields HIGH or CRITICAL severity', () {
      final severityHigh = RiskEngine.evaluate(
        type: HazardType.pothole,
        confidence: 0.94,
        distanceMeters: 15.0,
        normalizedArea: 0.06,
        lateralOffsetFromCenter: 0.02,
      );
      expect(severityHigh, HazardSeverity.high);

      final severityCritical = RiskEngine.evaluate(
        type: HazardType.pothole,
        confidence: 0.95,
        distanceMeters: 9.0,
        normalizedArea: 0.08,
        lateralOffsetFromCenter: 0.02,
      );
      expect(severityCritical, HazardSeverity.critical);
    });

    test('Distant small road crack yields LOW or MEDIUM severity', () {
      final severity = RiskEngine.evaluate(
        type: HazardType.roadCrack,
        confidence: 0.82,
        distanceMeters: 30.0,
        normalizedArea: 0.02,
        lateralOffsetFromCenter: 0.1,
      );
      expect(severity, HazardSeverity.low);
    });

    test('Voice alert phrasing matches risk level and hazard class', () {
      final det = Detection(
        id: 'TEST-1',
        type: HazardType.pothole,
        confidence: 0.94,
        boundingBox: const BoundingBox(left: 0.4, top: 0.5, width: 0.2, height: 0.15),
        distanceMeters: 15.0,
        severity: HazardSeverity.high,
      );
      final voice = RiskEngine.generateVoiceAlert(det);
      expect(voice, contains('pothole'));
      expect(voice, contains('15 meters ahead'));
    });
  });

  group('SimulatedDetectorService Sequence Tests', () {
    final service = SimulatedDetectorService();

    setUp(() async {
      await service.initialize();
    });

    test('0 to 5 seconds represents clear road (0 detections)', () {
      final dets = service.getDetectionsForCycleTime(2.5);
      expect(dets, isEmpty);
    });

    test('5 to 9 seconds detects ROAD CRACK with MEDIUM severity', () {
      final dets = service.getDetectionsForCycleTime(7.0);
      expect(dets.length, 1);
      expect(dets.first.type, HazardType.roadCrack);
      expect(dets.first.severity, HazardSeverity.medium);
      expect(dets.first.confidence, 0.87);
    });

    test('9 to 14 seconds detects POTHOLE with HIGH severity', () {
      final dets = service.getDetectionsForCycleTime(12.0);
      expect(dets.length, 1);
      expect(dets.first.type, HazardType.pothole);
      expect(dets.first.confidence, 0.94);
    });

    test('14 to 18 seconds detects PEDESTRIAN with CRITICAL severity', () {
      final dets = service.getDetectionsForCycleTime(16.0);
      expect(dets.length, 1);
      expect(dets.first.type, HazardType.pedestrian);
      expect(dets.first.severity, HazardSeverity.critical);
      expect(dets.first.confidence, 0.91);
    });

    test('18 to 23 seconds detects OBSTACLE with HIGH severity', () {
      final dets = service.getDetectionsForCycleTime(20.0);
      expect(dets.length, 1);
      expect(dets.first.type, HazardType.obstacle);
      expect(dets.first.confidence, 0.89);
    });
  });

  group('GeoJSON & Hazard Model Tests', () {
    test('Hazard model serializes to JSON and GeoJSON Feature correctly', () {
      final hazard = Hazard(
        id: 'HAZ-TEST-001',
        type: 'POTHOLE',
        confidence: 0.95,
        severity: 'HIGH',
        latitude: 28.6139,
        longitude: 77.2090,
        timestamp: DateTime(2026, 3, 30, 10, 30),
        distance: 14.5,
        source: 'EDGE_MODEL_INT8',
        status: 'LOGGED',
        roadName: 'Cyber Expressway Km 12',
      );

      final map = hazard.toMap();
      expect(map['id'], 'HAZ-TEST-001');
      expect(map['type'], 'POTHOLE');
      expect(map['confidence'], 0.95);

      final reconstructed = Hazard.fromMap(map);
      expect(reconstructed.id, hazard.id);
      expect(reconstructed.distance, hazard.distance);

      final geoJson = hazard.toGeoJsonFeature();
      expect(geoJson['type'], 'Feature');
      expect(geoJson['geometry']['type'], 'Point');
      expect(geoJson['geometry']['coordinates'], [77.2090, 28.6139]);
      expect(geoJson['properties']['hazard_type'], 'POTHOLE');
      expect(geoJson['properties']['severity'], 'HIGH');
    });

    test('GeoJsonService produces valid RFC 7946 FeatureCollection', () {
      final hazards = [
        Hazard(
          id: 'H1',
          type: 'POTHOLE',
          confidence: 0.92,
          severity: 'CRITICAL',
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          distance: 12.0,
        ),
        Hazard(
          id: 'H2',
          type: 'ROAD CRACK',
          confidence: 0.88,
          severity: 'MEDIUM',
          latitude: 28.6150,
          longitude: 77.2100,
          timestamp: DateTime.now(),
          distance: 25.0,
        ),
      ];

      final collection = GeoJsonService.generateFeatureCollection(hazards);
      expect(collection['type'], 'FeatureCollection');
      expect(collection['features'].length, 2);
      expect(collection['metadata']['total_hazards'], 2);
      expect(collection['metadata']['critical_count'], 1);

      final jsonStr = GeoJsonService.exportGeoJsonString(hazards);
      expect(jsonStr, contains('"type": "FeatureCollection"'));
      expect(jsonStr, contains('POTHOLE'));
    });
  });
}
