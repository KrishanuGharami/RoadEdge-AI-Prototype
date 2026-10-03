import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/detection.dart';
import 'risk_engine.dart';

/// AlertService coordinates Audio (TTS), Haptic, and Visual Warnings
/// Features smart debouncing to prevent repetitive audio saturation.
class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  FlutterTts? _tts;
  bool _isTtsAvailable = false;
  bool isMuted = false;

  // Debouncing / Cooldown map: HazardType -> last announcement time
  final Map<HazardType, DateTime> _lastAlertTimes = {};
  static const Duration _cooldownDuration = Duration(milliseconds: 3500);

  // Stream controller for visual HUD flash alerts
  final StreamController<Detection> _visualAlertController =
      StreamController<Detection>.broadcast();
  Stream<Detection> get visualAlertStream => _visualAlertController.stream;

  /// Initialize TTS safely
  Future<void> initialize() async {
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('en-US');
      await _tts?.setSpeechRate(0.52);
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.05);
      _isTtsAvailable = true;
      debugPrint('[AlertService] TTS Engine initialized successfully.');
    } catch (e) {
      _isTtsAvailable = false;
      debugPrint('[AlertService] TTS initialization failed gracefully: $e');
    }
  }

  /// Trigger multi-sensory alert for a detected hazard
  Future<void> triggerAlert(Detection detection) async {
    final now = DateTime.now();
    final lastTime = _lastAlertTimes[detection.type];

    // Check cooldown debouncing
    if (lastTime != null && now.difference(lastTime) < _cooldownDuration) {
      return; // Still in cooldown for this hazard type
    }

    _lastAlertTimes[detection.type] = now;

    // 1. Visual Warning Broadcast
    if (!_visualAlertController.isClosed) {
      _visualAlertController.add(detection);
    }

    // 2. Tactile / Haptic Alert
    _triggerHaptic(detection.severity);

    // 3. Audio / Voice Alert
    if (!isMuted) {
      final voicePhrase = RiskEngine.generateVoiceAlert(detection);
      await _speak(voicePhrase);
    }
  }

  /// Haptic feedback scaled to hazard severity
  void _triggerHaptic(HazardSeverity severity) {
    try {
      switch (severity) {
        case HazardSeverity.critical:
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 150), () {
            HapticFeedback.heavyImpact();
          });
          break;
        case HazardSeverity.high:
          HapticFeedback.heavyImpact();
          break;
        case HazardSeverity.medium:
          HapticFeedback.mediumImpact();
          break;
        case HazardSeverity.low:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      debugPrint('[AlertService] Haptic feedback error (non-fatal): $e');
    }
  }

  /// Safe TTS invocation
  Future<void> _speak(String message) async {
    if (!_isTtsAvailable || _tts == null) return;
    try {
      await _tts?.stop();
      await _tts?.speak(message);
    } catch (e) {
      debugPrint('[AlertService] TTS speech execution error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      _tts?.stop();
      _visualAlertController.close();
    } catch (_) {}
  }
}
