import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

/// Telemetry metric card for dashboard overview
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final bool isMonospace;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.isMonospace = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primaryCyan;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.hudSubheading.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: isMonospace
                ? AppTextStyles.telemetryLarge.copyWith(color: color, fontSize: 20)
                : AppTextStyles.hudHeading.copyWith(color: color, fontSize: 18),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyles.telemetrySmall.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
