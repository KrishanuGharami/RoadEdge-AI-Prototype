import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

/// LocationService manages GPS coordinates with seamless simulated trajectory fallback
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  bool _isLiveGps = false;
  double _currentLatitude = AppConstants.defaultLatitude;
  double _currentLongitude = AppConstants.defaultLongitude;
  double _currentSpeedKmh = 48.0;
  double _currentHeading = 42.0; // degrees
  String _statusMessage = 'Initializing GNSS...';

  StreamSubscription<Position>? _positionSubscription;
  Timer? _simulationTimer;

  bool get isLiveGps => _isLiveGps;
  double get latitude => _currentLatitude;
  double get longitude => _currentLongitude;
  double get speedKmh => _currentSpeedKmh;
  double get heading => _currentHeading;
  String get statusMessage => _statusMessage;

  /// Initialize location tracking
  Future<void> initialize() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _enableSimulatedLocation('GPS service disabled (Simulated trajectory active)');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _enableSimulatedLocation('GPS permission denied (Simulated trajectory active)');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _enableSimulatedLocation('GPS denied permanently (Simulated trajectory active)');
        return;
      }

      // Live GPS is available
      final Position currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      _currentLatitude = currentPos.latitude;
      _currentLongitude = currentPos.longitude;
      _currentSpeedKmh = (currentPos.speed * 3.6).clamp(0.0, 140.0);
      _currentHeading = currentPos.heading;
      _isLiveGps = true;
      _statusMessage = 'GNSS Locked (3D Precision)';

      // Subscribe to real-time updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen(
        (Position pos) {
          _currentLatitude = pos.latitude;
          _currentLongitude = pos.longitude;
          if (pos.speed > 0.5) {
            _currentSpeedKmh = (pos.speed * 3.6).clamp(0.0, 140.0);
          }
          if (pos.heading != 0.0) {
            _currentHeading = pos.heading;
          }
          _isLiveGps = true;
          _statusMessage = 'GNSS Active (${pos.accuracy.toStringAsFixed(1)}m)';
        },
        onError: (err) {
          debugPrint('[LocationService] Stream error ($err). Falling back to simulation.');
          _enableSimulatedLocation('GNSS Signal Lost');
        },
      );
    } catch (e) {
      debugPrint('[LocationService] Location init caught ($e). Enabling simulated driving trajectory.');
      _enableSimulatedLocation('Simulated GNSS Active');
    }
  }

  /// Smoothly advances vehicle position along simulated corridor
  void _enableSimulatedLocation(String reason) {
    _isLiveGps = false;
    _statusMessage = reason;

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      // Advance ~13 meters per second along 45 degree bearing
      // 1 deg lat ~= 111,000 meters; 13 meters ~= 0.000117 deg
      _currentLatitude += 0.000085;
      _currentLongitude += 0.000095;
      _currentSpeedKmh = 48.0 + (timer.tick % 5) * 1.5;
      _currentHeading = 42.0 + (timer.tick % 4) * 0.5;
    });
  }

  void dispose() {
    _positionSubscription?.cancel();
    _simulationTimer?.cancel();
  }
}
