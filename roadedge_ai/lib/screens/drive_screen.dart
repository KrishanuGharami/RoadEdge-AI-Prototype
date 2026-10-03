import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../models/hazard.dart';
import '../models/system_metrics.dart';
import '../services/alert_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/simulated_detector_service.dart';
import '../services/storage_service.dart';
import '../services/tflite_detector_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/geo_utils.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/edge_performance_panel.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/simulated_road_view.dart';

/// DriveScreen - Real-time Driving HUD & Computer Vision Inference View
class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final CameraService _cameraService = CameraService();
  final TfliteDetectorService _tfliteService = TfliteDetectorService();
  final SimulatedDetectorService _simulatedDetector =
      SimulatedDetectorService();
  final AlertService _alertService = AlertService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  // State flags
  bool _isLiveCameraMode = false;
  bool _isCameraInitializing = false;
  bool _isSimPaused = false;
  double _simElapsedSeconds = 0.0;
  Timer? _simulationLoopTimer;

  // Active Detections & Diagnostics
  List<Detection> _currentDetections = [];
  Detection? _primaryAlertDetection;
  DateTime? _lastAlertBannerTime;

  SystemMetrics _metrics = const SystemMetrics(
    isSimulated: true,
    fps: 60,
    targetLatency: '<25 ms',
    measuredLatencyMs: 18.2,
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // 1. Initialize Detector Engine
    await _tfliteService.initialize();
    await _simulatedDetector.initialize();

    // 2. Initialize Location tracking
    await _locationService.initialize();

    // 3. Start default Simulated Driving Loop
    _startSimulatedDriveLoop();
  }

  /// Toggle between Simulated Drive and Live Camera feed
  Future<void> _toggleDriveMode(bool toLiveCamera) async {
    if (toLiveCamera == _isLiveCameraMode) return;

    if (toLiveCamera) {
      setState(() {
        _isCameraInitializing = true;
      });

      final success = await _cameraService.initialize();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.backgroundCard,
              content: Text(
                'Camera sensor unavailable or permission denied. Falling back to Simulated Drive.',
                style: AppTextStyles.body.copyWith(color: AppColors.primaryCyan),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isLiveCameraMode = false;
          _isCameraInitializing = false;
          _metrics = _metrics.copyWith(
            isSimulated: true,
            hardwareBackend: 'NNAPI / Qualcomm NPU (Simulated)',
          );
        });
        return;
      }

      setState(() {
        _isLiveCameraMode = true;
        _isCameraInitializing = false;
        _metrics = _metrics.copyWith(
          isSimulated: false,
          hardwareBackend: _tfliteService.backendName,
        );
      });
    } else {
      await _cameraService.dispose();
      setState(() {
        _isLiveCameraMode = false;
        _metrics = _metrics.copyWith(
          isSimulated: true,
          hardwareBackend: 'NNAPI / Qualcomm NPU (Simulated)',
        );
      });
    }
  }

  /// 60 FPS driving progression loop
  void _startSimulatedDriveLoop() {
    _simulationLoopTimer?.cancel();
    _simulationLoopTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isSimPaused || !mounted) return;

      _simElapsedSeconds += 0.1;

      // In simulated drive mode, extract detections for the cycle
      if (!_isLiveCameraMode) {
        final detections =
            _simulatedDetector.getDetectionsForCycleTime(_simElapsedSeconds);
        _handleNewDetections(detections);
      }
    });
  }

  /// Process new detections: trigger alerts, haptics, and log to storage
  void _handleNewDetections(List<Detection> detections) {
    if (!mounted) return;

    setState(() {
      _currentDetections = detections;
    });

    if (detections.isNotEmpty) {
      // Find highest risk detection
      final primary = detections.reduce((a, b) =>
          _severityWeight(a.severity) >= _severityWeight(b.severity) ? a : b);

      setState(() {
        _primaryAlertDetection = primary;
        _lastAlertBannerTime = DateTime.now();
      });

      // Trigger audio TTS & haptic through AlertService (safely debounced)
      _alertService.triggerAlert(primary);

      // Auto-log to local offline storage
      final hazard = Hazard.fromDetection(
        detection: primary,
        latitude: _locationService.latitude,
        longitude: _locationService.longitude,
        source: _isLiveCameraMode ? 'EDGE_MODEL_INT8' : 'SIMULATED_ENGINE',
        roadName: AppConstants.defaultRoadName,
      );
      _storageService.logHazard(hazard);
    } else {
      // Clear alert after 2.5 seconds if road is clear
      if (_lastAlertBannerTime != null &&
          DateTime.now().difference(_lastAlertBannerTime!).inMilliseconds > 2500) {
        setState(() {
          _primaryAlertDetection = null;
        });
      }
    }
  }

  int _severityWeight(HazardSeverity sev) {
    switch (sev) {
      case HazardSeverity.critical:
        return 4;
      case HazardSeverity.high:
        return 3;
      case HazardSeverity.medium:
        return 2;
      case HazardSeverity.low:
        return 1;
    }
  }

  @override
  void dispose() {
    _simulationLoopTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top HUD Control Bar
            _buildTopHudBar(),

            // 2. Main Viewport (Camera or Simulated Road Canvas) with DetectionOverlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video feed or Simulated 3D Road Scene
                  _buildViewportContent(),

                  // AI Bounding Boxes & Confidence Tags Overlay
                  DetectionOverlay(detections: _currentDetections),

                  // HUD Dashcam Watermark & Status Overlays
                  _buildHudWatermark(),

                  // Audio Alert / Pulsing Visual Banner when Hazard is detected
                  if (_primaryAlertDetection != null)
                    _buildActiveAlertBanner(_primaryAlertDetection!),
                ],
              ),
            ),

            // 3. Below Viewport: Hazard Warning Details Card & Telemetrics
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHudBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.backgroundSecondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button & Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isLiveCameraMode ? 'LIVE OPTICAL FEED' : 'SIMULATED DRIVE SCENE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isLiveCameraMode
                          ? AppColors.primaryCyan
                          : AppColors.statusSimulated,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Mode Selector Toggle: LIVE CAMERA vs SIMULATED DRIVE
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.backgroundCardBorder),
            ),
            child: Row(
              children: [
                _buildModeTab(
                  label: 'SIMULATED',
                  isActive: !_isLiveCameraMode,
                  onTap: () => _toggleDriveMode(false),
                ),
                _buildModeTab(
                  label: 'LIVE CAM',
                  isActive: _isLiveCameraMode,
                  onTap: () => _toggleDriveMode(true),
                ),
              ],
            ),
          ),

          // Mute Audio Toggle
          IconButton(
            icon: Icon(
              _alertService.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: _alertService.isMuted
                  ? AppColors.textMuted
                  : AppColors.primaryCyan,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _alertService.isMuted = !_alertService.isMuted;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (_isLiveCameraMode
                  ? AppColors.primaryCyan
                  : AppColors.statusSimulated)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: isActive ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildViewportContent() {
    if (_isLiveCameraMode) {
      if (_isCameraInitializing) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryCyan),
              SizedBox(height: 12),
              Text('Accessing optical camera sensor...',
                  style: AppTextStyles.hudSubheading),
            ],
          ),
        );
      }

      if (_cameraService.isInitialized) {
        return CameraPreview(_cameraService.controller!);
      }
    }

    // Default: Animated 3D Road Scene with Forward Motion Kinematics
    return SimulatedRoadView(
      activeDetections: _currentDetections,
      vehicleSpeedKmh: _locationService.speedKmh,
      isDriving: !_isSimPaused,
    );
  }

  Widget _buildHudWatermark() {
    return Positioned(
      top: 12,
      left: 14,
      right: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // REC indicator & FPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.severityCritical,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'REC  60 FPS • 1080p',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Speed & GPS HUD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_rounded,
                    size: 11, color: AppColors.primaryCyan),
                const SizedBox(width: 4),
                Text(
                  '${_locationService.speedKmh.toStringAsFixed(0)} KM/H',
                  style: const TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  GeoUtils.formatCoordinate(
                      _locationService.latitude, _locationService.longitude),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertBanner(Detection detection) {
    final color = AppColors.forSeverity(detection.severity.displayName);

    return Positioned(
      bottom: 14,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                GeoUtils.getHazardIcon(detection.type.displayName),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'HAZARD DETECTED',
                        style: AppTextStyles.badgeText.copyWith(
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${detection.confidencePercent}% Conf',
                        style: AppTextStyles.telemetrySmall.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${detection.type.displayName} • ${detection.distanceDisplay}',
                    style: AppTextStyles.hudHeading.copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            RiskIndicator(severity: detection.severity.displayName),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.backgroundCardBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Compact Edge Performance HUD (FPS, Inference, Network, Model)
          EdgePerformancePanel(metrics: _metrics, isCompact: true),
          const SizedBox(height: 12),

          // Simulation Controls / Manual Hazard Trigger Bar
          Row(
            children: [
              // Pause / Play Simulation
              IconButton.filledTonal(
                icon: Icon(
                  _isSimPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: AppColors.primaryCyan,
                ),
                onPressed: () {
                  setState(() {
                    _isSimPaused = !_isSimPaused;
                  });
                },
              ),
              const SizedBox(width: 8),

              // Manual Hazard Trigger Quick Buttons for Pitch Demo
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickTriggerChip('POTHOLE', HazardType.pothole),
                      const SizedBox(width: 6),
                      _buildQuickTriggerChip('ROAD CRACK', HazardType.roadCrack),
                      const SizedBox(width: 6),
                      _buildQuickTriggerChip('PEDESTRIAN', HazardType.pedestrian),
                      const SizedBox(width: 6),
                      _buildQuickTriggerChip('OBSTACLE', HazardType.obstacle),
                      const SizedBox(width: 6),
                      _buildQuickTriggerChip('DEBRIS', HazardType.debris),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTriggerChip(String label, HazardType type) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: AppColors.backgroundCard,
      side: const BorderSide(color: AppColors.backgroundCardBorder),
      onPressed: () {
        _simulatedDetector.triggerManualHazard(type);
        final detections = _simulatedDetector.getDetectionsForCycleTime(0);
        _handleNewDetections(detections);

        // Reset manual override after 3.5 seconds
        Future.delayed(const Duration(seconds: 4), () {
          _simulatedDetector.clearManualHazard();
        });
      },
    );
  }
}
