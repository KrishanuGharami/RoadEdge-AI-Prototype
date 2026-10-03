import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GeoUtils {
  /// Calculate distance between two GPS coordinates in meters
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R; R = 6371000m
  }

  /// Format coordinates for automotive HUD display
  static String formatCoordinate(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir, ${lon.abs().toStringAsFixed(4)}° $lonDir';
  }

  /// Get appropriate Material Icon for hazard type
  static IconData getHazardIcon(String type) {
    final normalized = type.toUpperCase().replaceAll('_', ' ');
    if (normalized.contains('POTHOLE')) {
      return Icons.radio_button_checked_rounded;
    } else if (normalized.contains('CRACK')) {
      return Icons.broken_image_outlined;
    } else if (normalized.contains('OBSTACLE')) {
      return Icons.warning_rounded;
    } else if (normalized.contains('PEDESTRIAN')) {
      return Icons.directions_walk_rounded;
    } else if (normalized.contains('VEHICLE')) {
      return Icons.directions_car_filled_rounded;
    } else if (normalized.contains('DEBRIS')) {
      return Icons.grain_rounded;
    }
    return Icons.report_problem_rounded;
  }

  /// Get color for hazard type
  static Color getHazardColor(String severity) {
    return AppColors.forSeverity(severity);
  }
}
