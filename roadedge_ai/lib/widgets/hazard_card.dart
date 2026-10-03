import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hazard.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/geo_utils.dart';
import 'glass_card.dart';
import 'risk_indicator.dart';

/// Reusable card displaying detailed hazard detection record
class HazardCard extends StatelessWidget {
  final Hazard hazard;
  final VoidCallback? onTap;
  final bool showFullDetails;

  const HazardCard({
    super.key,
    required this.hazard,
    this.onTap,
    this.showFullDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppColors.forSeverity(hazard.severity);
    final icon = GeoUtils.getHazardIcon(hazard.type);
    final timeFormatted = DateFormat('HH:mm:ss').format(hazard.timestamp);
    final dateFormatted = DateFormat('MMM dd').format(hazard.timestamp);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: severityColor.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: severityColor.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: severityColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title and road name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.type,
                      style: AppTextStyles.hudHeading.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hazard.roadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Severity Indicator
              RiskIndicator(severity: hazard.severity),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.backgroundCardBorder),
          const SizedBox(height: 10),

          // Telemetry row: Confidence, Distance, Time, GPS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricChip(
                label: 'CONFIDENCE',
                value: '${(hazard.confidence * 100).round()}%',
                icon: Icons.verified_rounded,
                color: AppColors.primaryCyan,
              ),
              _buildMetricChip(
                label: 'DISTANCE',
                value: '${hazard.distance.toStringAsFixed(1)}m',
                icon: Icons.straighten_rounded,
                color: AppColors.primaryBlue,
              ),
              _buildMetricChip(
                label: 'TIMESTAMP',
                value: '$dateFormatted $timeFormatted',
                icon: Icons.access_time_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),

          if (showFullDetails) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.backgroundCardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded,
                          size: 13, color: AppColors.primaryCyan),
                      const SizedBox(width: 6),
                      Text(
                        GeoUtils.formatCoordinate(
                            hazard.latitude, hazard.longitude),
                        style: AppTextStyles.telemetrySmall,
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hazard.source,
                      style: AppTextStyles.badgeText.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.telemetrySmall.copyWith(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.telemetryMedium.copyWith(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
