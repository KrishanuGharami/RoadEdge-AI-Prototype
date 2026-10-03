import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';

/// Settings & Edge AI Model Architecture Information Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlertService _alertService = AlertService();
  final StorageService _storageService = StorageService();

  double _confidenceThreshold = AppConstants.defaultConfidenceThreshold;
  double _iouThreshold = AppConstants.defaultIouThreshold;
  bool _audioAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _audioAlertsEnabled = !_alertService.isMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MODEL & SYSTEM INFO'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hackathon Track Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.15),
                      AppColors.primaryBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryCyan.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 18, color: AppColors.primaryCyan),
                        const SizedBox(width: 8),
                        Text(
                          'NAVONMESH \'26 • TRACK PS-02',
                          style: AppTextStyles.badgeText.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Intelligent Road Hazard Detection',
                      style: AppTextStyles.hudHeading,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edge AI Computer Vision Prototype designed for automotive dashcams and municipal patrol vehicles.',
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Model Architecture & Hardware Acceleration Card
              Text('EDGE MODEL ARCHITECTURE',
                  style: AppTextStyles.hudSubheading.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSpecRow('Model Backbone', 'YOLOv8n / YOLO11n Nano'),
                    _buildSpecRow('Weight Quantization', 'INT8 Post-Training Quantized'),
                    _buildSpecRow('Input Tensor Shape', '1 × 640 × 640 × 3 (RGB)'),
                    _buildSpecRow('Runtime Framework', AppConstants.runtimeEngine),
                    _buildSpecRow('Hardware Acceleration', 'Qualcomm Hexagon NPU compatible'),
                    _buildSpecRow('Inference Backend', 'Android NNAPI / CPU Neon fallback'),
                    _buildSpecRow('Target Latency', 'Target <25 ms (On-Device NPU)'),
                    _buildSpecRow('Execution Policy', '100% Offline / Zero Cloud Dependency'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Privacy & Offline First Specification
              Text('PRIVACY & OFFLINE GUARANTEES',
                  style: AppTextStyles.hudSubheading.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.backgroundCardBorder),
                ),
                child: Column(
                  children: [
                    _buildPrivacyRow('VIDEO PROCESSING', 'ON DEVICE', AppColors.statusReady),
                    const Divider(color: AppColors.backgroundCardBorder, height: 16),
                    _buildPrivacyRow('CLOUD INGESTION', 'NOT REQUIRED', AppColors.statusReady),
                    const Divider(color: AppColors.backgroundCardBorder, height: 16),
                    _buildPrivacyRow('NETWORK ACCESS', 'OFFLINE INDEPENDENT', AppColors.statusReady),
                    const Divider(color: AppColors.backgroundCardBorder, height: 16),
                    _buildPrivacyRow('HAZARD DATA', 'LOCALLY ENCRYPTED', AppColors.primaryCyan),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detection Pipeline Tuners
              Text('DETECTION THRESHOLDS',
                  style: AppTextStyles.hudSubheading.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Confidence Threshold',
                            style: AppTextStyles.body),
                        Text(
                          '${(_confidenceThreshold * 100).round()}%',
                          style: AppTextStyles.telemetryMedium
                              .copyWith(color: AppColors.primaryCyan),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryCyan,
                        thumbColor: AppColors.primaryCyan,
                        overlayColor: AppColors.primaryCyan.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _confidenceThreshold,
                        min: 0.30,
                        max: 0.95,
                        divisions: 13,
                        onChanged: (val) {
                          setState(() => _confidenceThreshold = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NMS IoU Threshold', style: AppTextStyles.body),
                        Text(
                          '${(_iouThreshold * 100).round()}%',
                          style: AppTextStyles.telemetryMedium
                              .copyWith(color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryBlue,
                        thumbColor: AppColors.primaryBlue,
                        overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _iouThreshold,
                        min: 0.20,
                        max: 0.80,
                        divisions: 12,
                        onChanged: (val) {
                          setState(() => _iouThreshold = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Audio & Voice Driver Advisory Switch
              Text('AUDIO ADVISORY SETTINGS',
                  style: AppTextStyles.hudSubheading.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryCyan,
                  title: const Text('Voice Safety Alerts (TTS)',
                      style: AppTextStyles.hudSubheading),
                  subtitle: const Text(
                    'Announces hazard class and distance with automatic cooldown debouncing',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: _audioAlertsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _audioAlertsEnabled = val;
                      _alertService.isMuted = !val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Reset Data Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.severityCritical),
                    foregroundColor: AppColors.severityCritical,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                  label: const Text(
                    'CLEAR LOCAL HAZARD LOGS',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _storageService.clearAll();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Local hazard database cleared.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.telemetryMedium.copyWith(
                fontSize: 11,
                color: AppColors.primaryCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.telemetrySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(
            value,
            style: AppTextStyles.badgeText.copyWith(color: color, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
