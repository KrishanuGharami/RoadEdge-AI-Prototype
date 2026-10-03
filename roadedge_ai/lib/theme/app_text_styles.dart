import 'package:flutter/material.dart';
import 'app_colors.dart';

/// RoadEdge AI - Typography system
/// Crisp, high-contrast automotive dashboard typography with monospace telemetry
class AppTextStyles {
  // Brand Header
  static const TextStyle brandTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle brandSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: AppColors.primaryCyan,
  );

  // HUD & Telemetry Headings
  static const TextStyle hudHeading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle hudSubheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  // Monospace Telemetry (for Latency, FPS, Coordinates, Timestamps)
  static const TextStyle telemetryLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
    letterSpacing: 1.0,
    color: AppColors.primaryCyan,
  );

  static const TextStyle telemetryMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'monospace',
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle telemetrySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // Hazard Alert Text
  static const TextStyle hazardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle hazardDetail = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.primaryCyan,
  );

  // Body & Buttons
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: AppColors.background,
  );
}
