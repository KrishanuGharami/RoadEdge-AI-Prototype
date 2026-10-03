import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// CameraService abstraction
/// Interfaces with device camera sensor for real-time edge frame ingestion.
/// Gracefully falls back if camera permissions are denied or sensor is absent.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isInitialized = false;
  bool _isStreaming = false;
  String _statusMessage = 'Uninitialized';

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => _isStreaming;
  String get statusMessage => _statusMessage;

  /// Initialize camera hardware
  Future<bool> initialize() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _statusMessage = 'No optical sensors detected';
        _isInitialized = false;
        debugPrint('[CameraService] $_statusMessage');
        return false;
      }

      // Prioritize rear-facing automotive road view camera
      final camera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 720p is balanced for mobile edge CV pipelines
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _statusMessage = 'Camera active (${camera.lensDirection.name})';
      debugPrint('[CameraService] $_statusMessage');
      return true;
    } catch (e) {
      _isInitialized = false;
      _statusMessage = 'Camera unavailable ($e)';
      debugPrint('[CameraService] Graceful fallback on camera init: $e');
      return false;
    }
  }

  /// Start live frame ingestion callback
  Future<void> startImageStream(Function(CameraImage image) onFrame) async {
    if (!isInitialized || _isStreaming) return;
    try {
      await _controller?.startImageStream((CameraImage image) {
        if (_isStreaming) {
          onFrame(image);
        }
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('[CameraService] Image stream start error: $e');
      _isStreaming = false;
    }
  }

  /// Stop image streaming
  Future<void> stopImageStream() async {
    if (!isInitialized || !_isStreaming) return;
    try {
      await _controller?.stopImageStream();
      _isStreaming = false;
    } catch (e) {
      debugPrint('[CameraService] Image stream stop error: $e');
    }
  }

  /// Dispose camera hardware
  Future<void> dispose() async {
    try {
      if (_isStreaming) {
        await stopImageStream();
      }
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('[CameraService] Camera disposal error: $e');
    }
  }
}
