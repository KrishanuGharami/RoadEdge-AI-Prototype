/// Conditional export for TFLite detector service
/// Compiles native TFLite/FFI on Android/iOS/Desktop/VM and Web implementation on Web
export 'tflite_detector_service_web.dart'
    if (dart.library.io) 'tflite_detector_service_native.dart';
