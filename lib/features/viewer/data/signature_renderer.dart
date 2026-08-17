import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Converts finger strokes into a tightly cropped transparent PNG that can be
/// composited onto a scanned page without covering the document below it.
abstract final class SignatureRenderer {
  static Future<Uint8List?> render(
    List<List<ui.Offset>> strokes, {
    ui.Color ink = const ui.Color(0xFF1C1B3A),
  }) async {
    if (strokes.isEmpty) return null;
    final points = strokes.expand((stroke) => stroke).toList();
    if (points.isEmpty) return null;

    var minX = points.first.dx;
    var minY = points.first.dy;
    var maxX = points.first.dx;
    var maxY = points.first.dy;
    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      minY = math.min(minY, point.dy);
      maxX = math.max(maxX, point.dx);
      maxY = math.max(maxY, point.dy);
    }

    const padding = 18.0;
    final width = math.max(32, (maxX - minX + padding * 2).ceil());
    final height = math.max(32, (maxY - minY + padding * 2).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..translate(-minX + padding, -minY + padding);
    final paint = ui.Paint()
      ..color = ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 2, ui.Paint()..color = ink);
        continue;
      }
      final path = ui.Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
