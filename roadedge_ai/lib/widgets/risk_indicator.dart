import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Severity pill indicator with optional pulsing alert effect
class RiskIndicator extends StatefulWidget {
  final String severity;
  final bool animatePulsing;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const RiskIndicator({
    super.key,
    required this.severity,
    this.animatePulsing = false,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  State<RiskIndicator> createState() => _RiskIndicatorState();
}

class _RiskIndicatorState extends State<RiskIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animatePulsing ||
        widget.severity.toUpperCase() == 'CRITICAL' ||
        widget.severity.toUpperCase() == 'HIGH') {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSeverity(widget.severity);
    final isCritical = widget.severity.toUpperCase() == 'CRITICAL';

    return AnimatedBuilder(
      animation: _pulseAnimation ?? const AlwaysStoppedAnimation(0.3),
      builder: (context, child) {
        final glowOpacity = _pulseAnimation?.value ?? 0.3;

        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(isCritical ? 0.9 : 0.6),
              width: 1.4,
            ),
            boxShadow: isCritical
                ? [
                    BoxShadow(
                      color: color.withOpacity(glowOpacity),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.severity.toUpperCase(),
                style: AppTextStyles.badgeText.copyWith(
                  color: color,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
