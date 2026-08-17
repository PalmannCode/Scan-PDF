import 'package:flutter/services.dart';

/// On-device text recognition via Apple's Vision framework
/// (VNRecognizeTextRequest) over a platform channel — no binary ML pods,
/// identical behavior on simulator and device. Recognition never leaves
/// the phone.
class OcrService {
  static const MethodChannel _channel = MethodChannel('scanpdf/ocr');

  Future<String> recognizeFile(
    String imagePath, {
    List<String> languages = const [],
  }) async {
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'path': imagePath,
      'languages': languages,
    });
    return text ?? '';
  }

  /// Detects the strongest document quadrilateral using Apple Vision.
  /// Returns normalized TL/TR/BR/BL coordinates, or null when no stable
  /// rectangle is present.
  Future<List<double>?> detectDocumentCorners(String imagePath) async {
    final values = await _channel.invokeMethod<List<dynamic>>(
      'detectDocument',
      {'path': imagePath},
    );
    if (values == null || values.length != 8) return null;
    return values.map((value) => (value as num).toDouble()).toList();
  }

  Future<void> dispose() async {
    // Nothing to release — the channel is stateless.
  }
}
