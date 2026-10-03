import 'package:flutter/material.dart';
import '../models/system_metrics.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/tech_badge.dart';
import 'drive_screen.dart';
import 'hazard_history_screen.dart';
import 'hazard_map_screen.dart';
import 'settings_screen.dart';

/// RoadEdge AI - Home Command Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  SystemMetrics _metrics = const SystemMetrics();

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
  }

  void _refreshMetrics() {
    final hazards = _storageService.hazards;
    final total = hazards.length;
    final highRisk = hazards
        .where((h) => h.severity == 'CRITICAL' || h.severity == 'HIGH')
        .length;
    final avgConf = hazards.isEmpty
        ? 0.914
        : hazards.map((h) => h.confidence).reduce((a, b) => a + b) / total;

    setState(() {
      _metrics = _metrics.copyWith(
        hazardsToday: total,
        highRiskCount: highRisk,
        averageConfidence: avgConf,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header & Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryCyan.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: AppColors.primaryCyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            AppConstants.appName,
                            style: AppTextStyles.brandTitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppConstants.appSubtitle,
                        style: AppTextStyles.brandSubtitle,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // System Status Banner: ● EDGE ENGINE READY
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.statusReady.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.statusReady.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusReady,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusReady,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EDGE ENGINE READY',
                      style: AppTextStyles.badgeText.copyWith(
                        color: AppColors.statusReady,
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('•',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                    Text(
                      'Qualcomm NPU Compatible',
                      style: AppTextStyles.telemetrySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Technology Badges Row
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: [
                    TechBadge(
                        label: 'ON-DEVICE AI',
                        icon: Icons.memory_rounded,
                        isGlowing: true),
                    SizedBox(width: 8),
                    TechBadge(
                        label: 'INT8',
                        icon: Icons.compress_rounded,
                        color: AppColors.accentPurple),
                    SizedBox(width: 8),
                    TechBadge(
                        label: 'OFFLINE',
                        icon: Icons.wifi_off_rounded,
                        color: AppColors.statusReady),
                    SizedBox(width: 8),
                    TechBadge(
                        label: 'PRIVACY FIRST',
                        icon: Icons.shield_rounded,
                        color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    TechBadge(
                        label: 'QUALCOMM READY',
                        icon: Icons.developer_board_rounded,
                        color: AppColors.primaryCyan),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Telemetry Statistics Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  StatsCard(
                    label: 'HAZARDS TODAY',
                    value: '${_metrics.hazardsToday}',
                    subtitle: 'Local log count',
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppColors.primaryCyan,
                  ),
                  StatsCard(
                    label: 'HIGH RISK HAZARDS',
                    value: '${_metrics.highRiskCount}',
                    subtitle: 'Critical & High tier',
                    icon: Icons.dangerous_rounded,
                    accentColor: AppColors.severityCritical,
                  ),
                  StatsCard(
                    label: 'AVG CONFIDENCE',
                    value:
                        '${(_metrics.averageConfidence * 100).toStringAsFixed(1)}%',
                    subtitle: 'YOLOv8n INT8 Score',
                    icon: Icons.verified_rounded,
                    accentColor: AppColors.primaryBlue,
                  ),
                  StatsCard(
                    label: 'TARGET INFERENCE',
                    value: _metrics.targetLatency,
                    subtitle: 'Target <25 ms NPU',
                    icon: Icons.speed_rounded,
                    accentColor: AppColors.statusReady,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Primary CTA: START DRIVE
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCyan, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriveScreen(),
                        ),
                      );
                      _refreshMetrics();
                    },
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_rounded,
                              color: AppColors.background, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'START DRIVE',
                            style: AppTextStyles.buttonLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary CTA: VIEW HAZARD MAP
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryCyan.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HazardMapScreen(),
                        ),
                      );
                      _refreshMetrics();
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded,
                              color: AppColors.primaryCyan.withOpacity(0.9),
                              size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'VIEW HAZARD MAP',
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: AppColors.primaryCyan,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Access Navigation Row: Hazard History & Model Specs
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HazardHistoryScreen(),
                          ),
                        );
                        _refreshMetrics();
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded,
                              size: 20, color: AppColors.primaryCyan),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hazard History',
                                  style: AppTextStyles.hudSubheading),
                              Text('${_metrics.hazardsToday} recorded',
                                  style: AppTextStyles.telemetrySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.developer_board_rounded,
                              size: 20, color: AppColors.accentPurple),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Model Info',
                                  style: AppTextStyles.hudSubheading),
                              Text('NNAPI / INT8',
                                  style: AppTextStyles.telemetrySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Privacy & Offline First Guarantee Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.backgroundCardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.statusReady, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% ON-DEVICE PROCESSING',
                            style: AppTextStyles.badgeText.copyWith(
                              color: AppColors.statusReady,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Camera video frames never leave this device. Pure offline edge inference with zero cloud latency.',
                            style: AppTextStyles.body.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
