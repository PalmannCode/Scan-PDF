import 'package:flutter/services.dart';

class QrService {
  static const _channel = MethodChannel('scanpdf/ocr');

  Future<String?> scanFile(String path) =>
      _channel.invokeMethod<String>('scanBarcode', {'path': path});
}
