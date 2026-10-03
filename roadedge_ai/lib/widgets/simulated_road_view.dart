import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../theme/app_colors.dart';

/// SimulatedRoadView renders a 60 FPS animated 3D perspective driving road
/// with asphalt kinematics, lane dividers moving towards the camera,
/// horizon skyline, dashcam telemetrics, and road hazard renderings.
class SimulatedRoadView extends StatefulWidget {
  final List<Detection> activeDetections;
  final double vehicleSpeedKmh;
  final bool isDriving;

  const SimulatedRoadView({
    super.key,
    required this.activeDetections,
    this.vehicleSpeedKmh = 48.0,
    this.isDriving = true,
  });

  @override
  State<SimulatedRoadView> createState() => _SimulatedRoadViewState();
}

class _SimulatedRoadViewState extends State<SimulatedRoadView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SimulatedRoadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDriving && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isDriving && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _RoadScenePainter(
            animationValue: _animController.value,
            detections: widget.activeDetections,
            speedKmh: widget.vehicleSpeedKmh,
          ),
        );
      },
    );
  }
}

class _RoadScenePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final List<Detection> detections;
  final double speedKmh;

  _RoadScenePainter({
    required this.animationValue,
    required this.detections,
    required this.speedKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.44;
    final double vanishingX = size.width * 0.50;

    // 1. Sky & Atmosphere Background
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF060913),
          Color(0xFF0F172A),
          Color(0xFF1E293B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // Distant City Skyline Silhouettes
    _drawSkyline(canvas, size, horizonY);

    // Ground Verge / Grass Shoulder
    final groundPaint = Paint()..color = const Color(0xFF0D121B);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      groundPaint,
    );

    // 2. Asphalt Road Perspective Surface
    final roadPath = Path()
      ..moveTo(vanishingX - size.width * 0.10, horizonY)
      ..lineTo(vanishingX + size.width * 0.10, horizonY)
      ..lineTo(size.width * 0.98, size.height)
      ..lineTo(size.width * 0.02, size.height)
      ..close();

    final asphaltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF1A1F2C),
          Color(0xFF121620),
          Color(0xFF0B0E14),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawPath(roadPath, asphaltPaint);

    // 3. Road Shoulder Neon Edges
    final shoulderPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Left Shoulder
    canvas.drawLine(
      Offset(vanishingX - size.width * 0.10, horizonY),
      Offset(size.width * 0.02, size.height),
      shoulderPaint,
    );

    // Right Shoulder
    canvas.drawLine(
      Offset(vanishingX + size.width * 0.10, horizonY),
      Offset(size.width * 0.98, size.height),
      shoulderPaint,
    );

    // 4. Moving Center Dashed Line (Forward Kinematics)
    _drawMovingCenterLanes(canvas, size, vanishingX, horizonY);

    // 5. Draw Hazard Visuals directly on road
    _drawRoadHazards(canvas, size);

    // 6. Dashcam HUD Scanning Overlays & Horizon Pitch Reticle
    _drawDashcamHud(canvas, size, vanishingX, horizonY);
  }

  void _drawSkyline(Canvas canvas, Size size, double horizonY) {
    final skylinePaint = Paint()..color = const Color(0xFF111827);
    final buildings = [
      Rect.fromLTWH(size.width * 0.15, horizonY - 45, 30, 45),
      Rect.fromLTWH(size.width * 0.22, horizonY - 30, 22, 30),
      Rect.fromLTWH(size.width * 0.35, horizonY - 60, 40, 60),
      Rect.fromLTWH(size.width * 0.44, horizonY - 25, 20, 25),
      Rect.fromLTWH(size.width * 0.58, horizonY - 50, 35, 50),
      Rect.fromLTWH(size.width * 0.70, horizonY - 35, 25, 35),
      Rect.fromLTWH(size.width * 0.82, horizonY - 65, 45, 65),
    ];

    for (final b in buildings) {
      canvas.drawRect(b, skylinePaint);
    }

    // Horizon line glow
    final glowPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.2)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), glowPaint);
  }

  void _drawMovingCenterLanes(
    Canvas canvas,
    Size size,
    double vanishingX,
    double horizonY,
  ) {
    final lanePaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.85)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const int numDashes = 7;

    for (int i = 0; i < numDashes; i++) {
      // Perspective quadratic expansion as dash approaches viewer
      final double t = (i / numDashes + animationValue / numDashes) % 1.0;
      final double progress = math.pow(t, 2.2).toDouble();

      final double startY = horizonY + progress * (size.height - horizonY);
      final double dashLength = 12.0 + progress * 70.0;
      final double endY = (startY + dashLength).clamp(horizonY, size.height);

      if (startY >= horizonY && startY < size.height) {
        lanePaint.strokeWidth = 1.5 + progress * 6.0;
        canvas.drawLine(
          Offset(vanishingX, startY),
          Offset(vanishingX, endY),
          lanePaint,
        );
      }
    }
  }

  void _drawRoadHazards(Canvas canvas, Size size) {
    for (final det in detections) {
      final rect = det.boundingBox.toRect(size);

      switch (det.type) {
        case HazardType.pothole:
          _drawPotholeVisual(canvas, rect);
          break;
        case HazardType.roadCrack:
          _drawCrackVisual(canvas, rect);
          break;
        case HazardType.pedestrian:
          _drawPedestrianVisual(canvas, rect);
          break;
        case HazardType.obstacle:
          _drawObstacleVisual(canvas, rect);
          break;
        case HazardType.debris:
          _drawDebrisVisual(canvas, rect);
          break;
        case HazardType.vehicle:
          _drawVehicleVisual(canvas, rect);
          break;
      }
    }
  }

  void _drawPotholeVisual(Canvas canvas, Rect rect) {
    // Outer crater rim
    final rimPaint = Paint()
      ..color = const Color(0xFF2B3342)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, rimPaint);

    // Deep depression shadow
    final deepPaint = Paint()
      ..color = const Color(0xFF080B10)
      ..style = PaintingStyle.fill;
    final innerRect = rect.deflate(rect.width * 0.15);
    canvas.drawOval(innerRect, deepPaint);

    // Broken asphalt rim cracks
    final crackPaint = Paint()
      ..color = const Color(0xFF181E29)
      ..strokeWidth = 2.0;
    canvas.drawLine(rect.centerLeft, rect.centerLeft + const Offset(-8, 3), crackPaint);
    canvas.drawLine(rect.centerRight, rect.centerRight + const Offset(10, -2), crackPaint);
    canvas.drawLine(rect.bottomCenter, rect.bottomCenter + const Offset(4, 8), crackPaint);
  }

  void _drawCrackVisual(Canvas canvas, Rect rect) {
    final crackPaint = Paint()
      ..color = const Color(0xFF0A0D14)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(rect.left + rect.width * 0.1, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.35, rect.top + rect.height * 0.6)
      ..lineTo(rect.left + rect.width * 0.28, rect.top + rect.height * 0.4)
      ..lineTo(rect.left + rect.width * 0.70, rect.top + rect.height * 0.25)
      ..lineTo(rect.right - rect.width * 0.1, rect.top);

    canvas.drawPath(path, crackPaint);

    // Branching fissure
    final branchPath = Path()
      ..moveTo(rect.left + rect.width * 0.35, rect.top + rect.height * 0.6)
      ..lineTo(rect.left + rect.width * 0.55, rect.top + rect.height * 0.75);
    canvas.drawPath(branchPath, crackPaint);
  }

  void _drawPedestrianVisual(Canvas canvas, Rect rect) {
    final pedPaint = Paint()..color = const Color(0xFFFFB300);

    // Head
    final headCenter = Offset(rect.center.dx, rect.top + rect.height * 0.15);
    final headRadius = rect.width * 0.18;
    canvas.drawCircle(headCenter, headRadius, pedPaint);

    // Torso & legs
    final bodyPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = rect.width * 0.28
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      headCenter + Offset(0, headRadius + 2),
      Offset(rect.center.dx, rect.top + rect.height * 0.65),
      bodyPaint,
    );

    // Left leg & Right leg
    final legPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = rect.width * 0.16
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(rect.center.dx, rect.top + rect.height * 0.65),
      Offset(rect.left + rect.width * 0.25, rect.bottom),
      legPaint,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + rect.height * 0.65),
      Offset(rect.right - rect.width * 0.25, rect.bottom),
      legPaint,
    );
  }

  void _drawObstacleVisual(Canvas canvas, Rect rect) {
    final boxPaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      boxPaint,
    );

    // Hazard stripes across obstacle
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 3.5;
    canvas.drawLine(rect.topLeft, rect.bottomRight, stripePaint);
    canvas.drawLine(
      rect.centerLeft + const Offset(0, -5),
      rect.bottomCenter + const Offset(5, 0),
      stripePaint,
    );
  }

  void _drawDebrisVisual(Canvas canvas, Rect rect) {
    final debrisPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(rect.center, rect.width * 0.35, debrisPaint);
    canvas.drawCircle(rect.center + const Offset(-6, 4), rect.width * 0.22, debrisPaint);
    canvas.drawCircle(rect.center + const Offset(8, -2), rect.width * 0.18, debrisPaint);
  }

  void _drawVehicleVisual(Canvas canvas, Rect rect) {
    final carPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      carPaint,
    );

    // Tail lights
    final lightPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.2, rect.bottom - rect.height * 0.25),
      rect.width * 0.08,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(rect.right - rect.width * 0.2, rect.bottom - rect.height * 0.25),
      rect.width * 0.08,
      lightPaint,
    );
  }

  void _drawDashcamHud(
    Canvas canvas,
    Size size,
    double vanishingX,
    double horizonY,
  ) {
    // Center Horizon Crosshair Reticle
    final reticlePaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(vanishingX - 20, horizonY),
      Offset(vanishingX + 20, horizonY),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(vanishingX, horizonY - 15),
      Offset(vanishingX, horizonY + 15),
      reticlePaint,
    );

    // Tactical pitch ladder dashes
    for (int step = 1; step <= 2; step++) {
      final yOffset = step * 25.0;
      canvas.drawLine(
        Offset(vanishingX - 35, horizonY + yOffset),
        Offset(vanishingX - 15, horizonY + yOffset),
        reticlePaint,
      );
      canvas.drawLine(
        Offset(vanishingX + 15, horizonY + yOffset),
        Offset(vanishingX + 35, horizonY + yOffset),
        reticlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadScenePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.detections != detections ||
        oldDelegate.speedKmh != speedKmh;
  }
}
