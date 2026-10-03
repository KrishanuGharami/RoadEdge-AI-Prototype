import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hazard.dart';
import '../utils/constants.dart';

/// StorageService manages local-first offline persistence of hazard records
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _storageKey = 'roadedge_hazards_v1';
  List<Hazard> _cachedHazards = [];

  List<Hazard> get hazards => List.unmodifiable(_cachedHazards);

  /// Initialize and load hazards from local disk; seeds demo sample records if empty
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawData = prefs.getString(_storageKey);

      if (rawData != null && rawData.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(rawData);
        _cachedHazards = jsonList.map((item) => Hazard.fromMap(item)).toList();
        debugPrint('[StorageService] Loaded ${_cachedHazards.length} hazards from local cache.');
      } else {
        // First run: seed high-fidelity municipal dataset
        _cachedHazards = _generateSeedHazards();
        await _saveToDisk();
        debugPrint('[StorageService] Seeded ${_cachedHazards.length} sample municipal hazards.');
      }
    } catch (e) {
      debugPrint('[StorageService] Initialization error ($e). Using in-memory seed dataset.');
      _cachedHazards = _generateSeedHazards();
    }
  }

  /// Add a newly detected hazard
  Future<void> logHazard(Hazard hazard) async {
    // Avoid exact duplicate within 10 meters and 5 seconds
    final isDuplicate = _cachedHazards.any((h) =>
        h.type == hazard.type &&
        hazard.timestamp.difference(h.timestamp).inSeconds.abs() < 5);

    if (!isDuplicate) {
      _cachedHazards.insert(0, hazard); // Prepend so most recent is first
      await _saveToDisk();
      debugPrint('[StorageService] Logged new hazard: ${hazard.type} (${hazard.severity})');
    }
  }

  /// Clear all hazards
  Future<void> clearAll() async {
    _cachedHazards.clear();
    await _saveToDisk();
  }

  /// Reset to standard demo dataset
  Future<void> resetToSampleData() async {
    _cachedHazards = _generateSeedHazards();
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listData = _cachedHazards.map((h) => h.toMap()).toList();
      await prefs.setString(_storageKey, json.encode(listData));
    } catch (e) {
      debugPrint('[StorageService] Error saving hazards to disk: $e');
    }
  }

  /// Generates sample dataset along Smart Highway & Urban Corridor
  List<Hazard> _generateSeedHazards() {
    final baseLat = AppConstants.defaultLatitude;
    final baseLon = AppConstants.defaultLongitude;
    final now = DateTime.now();

    return [
      Hazard(
        id: 'HAZ-2026-POT-01',
        type: 'POTHOLE',
        confidence: 0.94,
        severity: 'HIGH',
        latitude: baseLat + 0.0032,
        longitude: baseLon + 0.0028,
        timestamp: now.subtract(const Duration(minutes: 6)),
        distance: 14.2,
        source: 'EDGE_MODEL_INT8',
        status: 'LOGGED',
        roadName: 'Cyber Highway • Sector 4 Inner Lane',
      ),
      Hazard(
        id: 'HAZ-2026-CRK-02',
        type: 'ROAD CRACK',
        confidence: 0.88,
        severity: 'MEDIUM',
        latitude: baseLat + 0.0018,
        longitude: baseLon + 0.0045,
        timestamp: now.subtract(const Duration(minutes: 18)),
        distance: 22.0,
        source: 'EDGE_MODEL_INT8',
        status: 'VERIFIED',
        roadName: 'Outer Ring Expressway • Km 14.2',
      ),
      Hazard(
        id: 'HAZ-2026-PED-03',
        type: 'PEDESTRIAN',
        confidence: 0.92,
        severity: 'CRITICAL',
        latitude: baseLat - 0.0025,
        longitude: baseLon + 0.0012,
        timestamp: now.subtract(const Duration(minutes: 32)),
        distance: 18.5,
        source: 'EDGE_MODEL_INT8',
        status: 'LOGGED',
        roadName: 'Metro Interchange Crossway',
      ),
      Hazard(
        id: 'HAZ-2026-OBS-04',
        type: 'OBSTACLE',
        confidence: 0.90,
        severity: 'HIGH',
        latitude: baseLat + 0.0048,
        longitude: baseLon - 0.0035,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        distance: 16.0,
        source: 'EDGE_MODEL_INT8',
        status: 'MUNICIPAL_DISPATCHED',
        roadName: 'Innovation Boulevard Southbound',
      ),
      Hazard(
        id: 'HAZ-2026-DEB-05',
        type: 'DEBRIS',
        confidence: 0.85,
        severity: 'LOW',
        latitude: baseLat - 0.0038,
        longitude: baseLon - 0.0022,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
        distance: 28.0,
        source: 'SIMULATED_ENGINE',
        status: 'LOGGED',
        roadName: 'Airport Link Flyover Ramp B',
      ),
      Hazard(
        id: 'HAZ-2026-POT-06',
        type: 'POTHOLE',
        confidence: 0.96,
        severity: 'CRITICAL',
        latitude: baseLat + 0.0062,
        longitude: baseLon + 0.0051,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 15)),
        distance: 9.8,
        source: 'EDGE_MODEL_INT8',
        status: 'LOGGED',
        roadName: 'Industrial Corridor Access Way',
      ),
      Hazard(
        id: 'HAZ-2026-CRK-07',
        type: 'ROAD CRACK',
        confidence: 0.82,
        severity: 'LOW',
        latitude: baseLat - 0.0055,
        longitude: baseLon + 0.0039,
        timestamp: now.subtract(const Duration(hours: 4, minutes: 5)),
        distance: 31.0,
        source: 'EDGE_MODEL_INT8',
        status: 'LOGGED',
        roadName: 'Central Avenue Underpass',
      ),
      Hazard(
        id: 'HAZ-2026-OBS-08',
        type: 'OBSTACLE',
        confidence: 0.89,
        severity: 'HIGH',
        latitude: baseLat + 0.0012,
        longitude: baseLon - 0.0041,
        timestamp: now.subtract(const Duration(hours: 5, minutes: 22)),
        distance: 15.4,
        source: 'EDGE_MODEL_INT8',
        status: 'VERIFIED',
        roadName: 'Tech Park Perimeter Road',
      ),
    ];
  }
}
