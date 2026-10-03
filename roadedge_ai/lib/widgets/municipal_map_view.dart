import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/hazard.dart';
import '../theme/app_colors.dart';

/// Offline Municipal Intelligence Vector GIS Map
/// Visualizes local hazard clusters, GPS pins, and severity hotspots
/// completely offline without third-party tile server dependencies.
class MunicipalMapView extends StatefulWidget {
  final List<Hazard> hazards;
  final Hazard? selectedHazard;
  final ValueChanged<Hazard>? onHazardSelected;

  const MunicipalMapView({
    super.key,
    required this.hazards,
    this.selectedHazard,
    this.onHazardSelected,
  });

  @override
  State<MunicipalMapView> createState() => _MunicipalMapViewState();
}

class _MunicipalMapViewState extends State<MunicipalMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, size),
          child: AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _MunicipalMapPainter(
                  hazards: widget.hazards,
                  selectedHazard: widget.selectedHazard,
                  radarAngle: _radarController.value * 2 * math.pi,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTap(Offset tapPos, Size size) {
    if (widget.hazards.isEmpty) return;

    Hazard? closest;
    double minDistance = 35.0; // Click radius in pixels

    for (final hazard in widget.hazards) {
      final pinPos = _calculatePinPosition(hazard, size);
      final dist = (pinPos - tapPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closest = hazard;
      }
    }

    if (closest != null && widget.onHazardSelected != null) {
      widget.onHazardSelected!(closest);
    }
  }

  static Offset _calculatePinPosition(Hazard hazard, Size size) {
    // Center point around base coordinates (New Delhi / Smart Corridor)
    const baseLat = 28.6139;
    const baseLon = 77.2090;
    const latSpan = 0.016; // approx 1.8km radius
    const lonSpan = 0.016;

    final normX = ((hazard.longitude - (baseLon - lonSpan / 2)) / lonSpan)
        .clamp(0.05, 0.95);
    final normY = (1.0 - (hazard.latitude - (baseLat - latSpan / 2)) / latSpan)
        .clamp(0.05, 0.95);

    return Offset(normX * size.width, normY * size.height);
  }
}

class _MunicipalMapPainter extends CustomPainter {
  final List<Hazard> hazards;
  final Hazard? selectedHazard;
  final double radarAngle;

  _MunicipalMapPainter({
    required this.hazards,
    required this.selectedHazard,
    required this.radarAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark GIS Background
    final bgPaint = Paint()..color = const Color(0xFF090D16);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Coordinate Grid Lines
    _drawGrid(canvas, size);

    // 3. Arterial Roads & Ring Corridors
    _drawRoadNetwork(canvas, size);

    // 4. Municipal Radar Sweep from City Center
    _drawRadarSweep(canvas, size);

    // 5. Cluster Heat Zones / Hotspot Radii
    _drawHotspotCircles(canvas, size);

    // 6. Hazard Pins
    _drawHazardPins(canvas, size);

    // 7. Tactical Compass & Telemetry Legend
    _drawCompassLegend(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF141C2E)
      ..strokeWidth = 1.0;

    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawRoadNetwork(Canvas canvas, Size size) {
    // Major Expressway (Diagonal Arterial)
    final expresswayPaint = Paint()
      ..color = const Color(0xFF22314E)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(size.width * 0.05, size.height * 0.85)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.65,
        size.width * 0.65,
        size.height * 0.35,
        size.width * 0.95,
        size.height * 0.15,
      );
    canvas.drawPath(highwayPath, expresswayPaint);

    // Arterial Secondary Road
    final arterialPaint = Paint()
      ..color = const Color(0xFF19243A)
      ..strokeWidth = 4.5;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.25),
      Offset(size.width * 0.9, size.height * 0.75),
      arterialPaint,
    );

    // Cross Street
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.90),
      Offset(size.width * 0.85, size.height * 0.20),
      arterialPaint,
    );

    // Ring Road Outer Loop
    final ringPaint = Paint()
      ..color = const Color(0xFF1C2740)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.38,
      ringPaint,
    );
  }

  void _drawRadarSweep(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.45;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.primaryCyan.withOpacity(0.0),
          AppColors.primaryCyan.withOpacity(0.12),
        ],
        transform: GradientRotation(radarAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Outer radar ring
    final radarBorder = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, radarBorder);
    canvas.drawCircle(center, radius * 0.65, radarBorder);
  }

  void _drawHotspotCircles(Canvas canvas, Size size) {
    for (final hazard in hazards) {
      if (hazard.severity == 'CRITICAL' || hazard.severity == 'HIGH') {
        final pos = _MunicipalMapViewState._calculatePinPosition(hazard, size);
        final color = AppColors.forSeverity(hazard.severity);

        final heatPaint = Paint()
          ..color = color.withOpacity(0.08)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 32.0, heatPaint);

        final ringPaint = Paint()
          ..color = color.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pos, 22.0, ringPaint);
      }
    }
  }

  void _drawHazardPins(Canvas canvas, Size size) {
    for (final hazard in hazards) {
      final pos = _MunicipalMapViewState._calculatePinPosition(hazard, size);
      final isSelected = selectedHazard?.id == hazard.id;
      final color = AppColors.forSeverity(hazard.severity);

      // Pin Outer Glow if selected
      if (isSelected) {
        final selectGlow = Paint()
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 18.0, selectGlow);

        final selectRing = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, 14.0, selectRing);
      }

      // Pin Body
      final pinBg = Paint()
        ..color = isSelected ? Colors.white : AppColors.backgroundSecondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 9.0, pinBg);

      final pinBorder = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(pos, 9.0, pinBorder);

      // Center dot
      final centerDot = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 4.0, centerDot);
    }
  }

  void _drawCompassLegend(Canvas canvas, Size size) {
    // Top-right compass
    final compassCenter = Offset(size.width - 28, 28);
    final compassPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(compassCenter, 14, compassPaint);

    // North Pointer (Red)
    final northPaint = Paint()..color = AppColors.severityCritical;
    final path = Path()
      ..moveTo(compassCenter.dx, compassCenter.dy - 12)
      ..lineTo(compassCenter.dx - 3, compassCenter.dy)
      ..lineTo(compassCenter.dx + 3, compassCenter.dy)
      ..close();
    canvas.drawPath(path, northPaint);

    // N label
    const textSpan = TextSpan(
      text: 'N',
      style: TextStyle(
        color: AppColors.severityCritical,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(compassCenter.dx - 3, compassCenter.dy - 24));
  }

  @override
  bool shouldRepaint(covariant _MunicipalMapPainter oldDelegate) {
    return oldDelegate.radarAngle != radarAngle ||
        oldDelegate.selectedHazard != selectedHazard ||
        oldDelegate.hazards != hazards;
  }
}
