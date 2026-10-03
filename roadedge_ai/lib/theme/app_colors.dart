import 'package:flutter/material.dart';

/// RoadEdge AI - Dark Automotive HUD Color Palette
/// Designed for high-contrast visibility, night/day driving HUD clarity,
/// and futuristic edge-AI dashboard aesthetics.
class AppColors {
  // Backgrounds - Deep Obsidian & Void Tones
  static const Color background = Color(0xFF0A0E17);
  static const Color backgroundSecondary = Color(0xFF111726);
  static const Color backgroundCard = Color(0xFF161E31);
  static const Color backgroundCardBorder = Color(0xFF24304D);
  static const Color surfaceGlass = Color(0x33162238);
  static const Color glassBorder = Color(0x3300F2FE);

  // Primary Cyber Accents
  static const Color primaryCyan = Color(0xFF00F2FE);
  static const Color primaryBlue = Color(0xFF4FACFE);
  static const Color accentNeon = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF7F00FF);
  
  // Status & Telemetry
  static const Color statusReady = Color(0xFF00E676);
  static const Color statusSimulated = Color(0xFFFFB300);
  static const Color statusLive = Color(0xFF00E5FF);
  static const Color statusError = Color(0xFFFF1744);
  static const Color offlineBadge = Color(0xFF78909C);

  // Hazard Severity Scale
  static const Color severityLow = Color(0xFF00E5FF);       // Cyan / Greenish
  static const Color severityMedium = Color(0xFFFFB300);    // Cyber Amber
  static const Color severityHigh = Color(0xFFFF6D00);      // Vivid Orange
  static const Color severityCritical = Color(0xFFFF1744);  // High-Voltage Crimson

  // Text & Icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color textHighlight = Color(0xFF00F2FE);

  // HUD Specific
  static const Color hudGrid = Color(0x1A00F2FE);
  static const Color hudCrosshair = Color(0x6600F2FE);
  static const Color hudPulsingAlert = Color(0x4DFF1744);
  static const Color roadSurface = Color(0xFF151922);
  static const Color roadMarking = Color(0xFFE0E0E0);
  static const Color laneGlow = Color(0x4000E5FF);

  // Helper method to get color for hazard severity
  static Color forSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return severityCritical;
      case 'HIGH':
        return severityHigh;
      case 'MEDIUM':
        return severityMedium;
      case 'LOW':
      default:
        return severityLow;
    }
  }
}
