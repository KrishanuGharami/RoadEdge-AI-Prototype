import 'package:flutter/material.dart';
import '../models/system_metrics.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

/// Edge Performance & Diagnostics HUD Panel
/// Exposes real-time on-device compute metrics, target latency, and hardware acceleration status.
class EdgePerformancePanel extends StatelessWidget {
  final SystemMetrics metrics;
  final bool isCompact;

  const EdgePerformancePanel({
    super.key,
    required this.metrics,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundCardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem(
              title: 'FPS',
              value: '${metrics.fps}',
              color: AppColors.primaryCyan,
            ),
            _buildDivider(),
            _buildItem(
              title: 'INFERENCE',
              value: metrics.targetLatency,
              sub: 'Target',
              color: AppColors.primaryBlue,
            ),
            _buildDivider(),
            _buildItem(
              title: 'NETWORK',
              value: metrics.networkStatus,
              color: AppColors.statusReady,
            ),
            _buildDivider(),
            _buildItem(
              title: 'MODEL',
              value: 'YOLO INT8',
              color: AppColors.textHighlight,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusReady,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EDGE PERFORMANCE & HARDWARE',
                    style: AppTextStyles.hudSubheading.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ON-DEVICE',
                  style: AppTextStyles.badgeText.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary 4 metrics grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'PIPELINE FPS',
                  value: '${metrics.fps}',
                  detail: 'Target 60 FPS UI',
                  icon: Icons.speed_rounded,
                  color: AppColors.primaryCyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'INFERENCE',
                  value: metrics.targetLatency,
                  detail: 'Target (<25 ms NPU)',
                  icon: Icons.timer_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'NETWORK STATE',
                  value: metrics.networkStatus,
                  detail: 'Zero cloud upload',
                  icon: Icons.wifi_off_rounded,
                  color: AppColors.statusReady,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'QUANTIZATION',
                  value: 'INT8 Precision',
                  detail: '640x640 Input Tensor',
                  icon: Icons.memory_rounded,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hardware Backend card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.backgroundCardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_board_rounded,
                    size: 16, color: AppColors.primaryCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCELERATION ENGINE',
                        style: AppTextStyles.telemetrySmall.copyWith(fontSize: 9),
                      ),
                      Text(
                        metrics.hardwareBackend,
                        style: AppTextStyles.telemetryMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LITERT / NNAPI',
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.primaryCyan,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String value,
    String? sub,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.telemetrySmall.copyWith(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.telemetryMedium.copyWith(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(width: 3),
              Text(
                sub,
                style: AppTextStyles.telemetrySmall.copyWith(fontSize: 8),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.backgroundCardBorder,
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.backgroundCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.telemetrySmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.telemetryMedium.copyWith(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTextStyles.telemetrySmall.copyWith(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
