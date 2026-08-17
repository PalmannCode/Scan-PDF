import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:scanpdf/features/viewer/data/signature_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signature rendering produces cropped transparent PNG ink', () async {
    final bytes = await SignatureRenderer.render(const [
      [Offset(120, 100), Offset(145, 125), Offset(180, 105)],
    ]);

    expect(bytes, isNotNull);
    final decoded = img.decodePng(bytes!);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThan(100));
    expect(decoded.height, lessThan(80));

    final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
    var hasTransparent = false;
    var hasInk = false;
    for (var i = 3; i < rgba.length; i += 4) {
      final alpha = rgba[i];
      hasTransparent |= alpha == 0;
      hasInk |= alpha > 0;
    }
    expect(rgba, isNotEmpty);
    expect(hasTransparent, isTrue);
    expect(hasInk, isTrue);
  });
}
