import 'dart:io';

import 'package:flutter/services.dart';

/// Uses PDFKit on iOS to write an encrypted PDF copy. Password protection is
/// deliberately performed natively because the Dart PDF renderer does not
/// expose PDF encryption.
class PdfSecurityService {
  const PdfSecurityService();

  static const _channel = MethodChannel('scanpdf/pdf_security');

  Future<File> protect({
    required File source,
    required String password,
    required String outputPath,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Password-protected PDF export requires iOS.');
    }
    if (password.length < 4) {
      throw ArgumentError('Use a password with at least 4 characters.');
    }
    final path = await _channel.invokeMethod<String>('protect', {
      'source': source.path,
      'output': outputPath,
      'password': password,
    });
    if (path == null || path.isEmpty) {
      throw StateError('The protected PDF could not be created.');
    }
    return File(path);
  }
}
