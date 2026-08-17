import 'package:flutter/services.dart';

/// On-device text recognition via Apple's Vision framework
/// (VNRecognizeTextRequest) over a platform channel — no binary ML pods,
/// identical behavior on simulator and device. Recognition never leaves
/// the phone.
class OcrService {
  static const MethodChannel _channel = MethodChannel('scanpdf/ocr');

  Future<String> recognizeFile(String imagePath) async {
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'path': imagePath,
    });
    return text ?? '';
  }

  Future<void> dispose() async {
    // Nothing to release — the channel is stateless.
  }
}
