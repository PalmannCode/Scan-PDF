import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (Latin bundle). One recognizer instance is
/// reused; callers must [dispose] when the owning scope dies.
class OcrService {
  OcrService() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<String> recognizeFile(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  Future<void> dispose() => _recognizer.close();
}
