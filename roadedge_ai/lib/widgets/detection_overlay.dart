import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../theme/app_colors.dart';

/// DetectionOverlay renders tactical bounding boxes, confidence tags,
/// and severity markers over camera feed or simulated road stream.
class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;

  const DetectionOverlay({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _DetectionPainter(detections),
      child: Container(),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  _DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final rect = detection.boundingBox.toRect(size);
      final color = AppColors.forSeverity(detection.severity.displayName);
      final isHighOrCritical =
          detection.severity == HazardSeverity.critical ||
          detection.severity == HazardSeverity.high;

      // 1. Semi-transparent fill
      final fillPaint = Paint()
        ..color = color.withOpacity(isHighOrCritical ? 0.15 : 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );

      // 2. Main Bounding Box Border
      final borderPaint = Paint()
        ..color = color.withOpacity(0.85)
        ..strokeWidth = isHighOrCritical ? 2.2 : 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      // 3. Tactical Corner Reticles
      _drawCornerReticles(canvas, rect, color, isHighOrCritical ? 14.0 : 10.0);

      // 4. Header Label Pill: CLASS • CONFIDENCE% • SEVERITY
      final labelText =
          '${detection.type.displayName}  ${detection.confidencePercent}% • ${detection.severity.displayName}';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final pillWidth = textPainter.width + 16;
      final pillHeight = textPainter.height + 8;
      final pillLeft = rect.left.clamp(4.0, size.width - pillWidth - 4.0);
      final pillTop = (rect.top - pillHeight - 4).clamp(4.0, size.height - pillHeight);

      final pillRect = Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight);
      final pillBgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(5)),
        pillBgPaint,
      );

      textPainter.paint(
        canvas,
        Offset(pillLeft + 8, pillTop + 4),
      );

      // 5. Distance Badge at bottom of bounding box
      final distText = '${detection.distanceMeters.toStringAsFixed(0)}m';
      final distSpan = TextSpan(
        text: distText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      final distPainter = TextPainter(
        text: distSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final distRect = Rect.fromLTWH(
        rect.right - distPainter.width - 12,
        rect.bottom + 4,
        distPainter.width + 10,
        distPainter.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(distRect, const Radius.circular(4)),
        Paint()..color = AppColors.background.withOpacity(0.85),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(distRect, const Radius.circular(4)),
        Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      distPainter.paint(canvas, Offset(distRect.left + 5, distRect.top + 2));
    }
  }

  void _drawCornerReticles(
      Canvas canvas, Rect rect, Color color, double reticleLength) {
    final reticlePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top Left
    canvas.drawLine(
        rect.topLeft, rect.topLeft + Offset(reticleLength, 0), reticlePaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + Offset(0, reticleLength), reticlePaint);

    // Top Right
    canvas.drawLine(
        rect.topRight, rect.topRight + Offset(-reticleLength, 0), reticlePaint);
    canvas.drawLine(
        rect.topRight, rect.topRight + Offset(0, reticleLength), reticlePaint);

    // Bottom Left
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + Offset(reticleLength, 0), reticlePaint);
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + Offset(0, -reticleLength), reticlePaint);

    // Bottom Right
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + Offset(-reticleLength, 0), reticlePaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + Offset(0, -reticleLength), reticlePaint);
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
