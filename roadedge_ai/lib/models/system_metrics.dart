/// Telemetry & Edge AI runtime metrics for the automotive HUD
class SystemMetrics {
  final int fps;
  final String targetLatency;
  final double measuredLatencyMs;
  final String networkStatus;
  final String modelName;
  final String hardwareBackend;
  final bool isSimulated;
  final String gpsStatus;
  final double vehicleSpeedKmh;
  final int hazardsToday;
  final int highRiskCount;
  final double averageConfidence;

  const SystemMetrics({
    this.fps = 60,
    this.targetLatency = '<25 ms',
    this.measuredLatencyMs = 18.4,
    this.networkStatus = 'OFFLINE',
    this.modelName = 'YOLOv8n-RoadHazard INT8',
    this.hardwareBackend = 'NNAPI / Qualcomm NPU compatible',
    this.isSimulated = true,
    this.gpsStatus = 'ACTIVE (4G/GNSS)',
    this.vehicleSpeedKmh = 48.0,
    this.hazardsToday = 24,
    this.highRiskCount = 6,
    this.averageConfidence = 0.914,
  });

  SystemMetrics copyWith({
    int? fps,
    String? targetLatency,
    double? measuredLatencyMs,
    String? networkStatus,
    String? modelName,
    String? hardwareBackend,
    bool? isSimulated,
    String? gpsStatus,
    double? vehicleSpeedKmh,
    int? hazardsToday,
    int? highRiskCount,
    double? averageConfidence,
  }) {
    return SystemMetrics(
      fps: fps ?? this.fps,
      targetLatency: targetLatency ?? this.targetLatency,
      measuredLatencyMs: measuredLatencyMs ?? this.measuredLatencyMs,
      networkStatus: networkStatus ?? this.networkStatus,
      modelName: modelName ?? this.modelName,
      hardwareBackend: hardwareBackend ?? this.hardwareBackend,
      isSimulated: isSimulated ?? this.isSimulated,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      vehicleSpeedKmh: vehicleSpeedKmh ?? this.vehicleSpeedKmh,
      hazardsToday: hazardsToday ?? this.hazardsToday,
      highRiskCount: highRiskCount ?? this.highRiskCount,
      averageConfidence: averageConfidence ?? this.averageConfidence,
    );
  }
}
