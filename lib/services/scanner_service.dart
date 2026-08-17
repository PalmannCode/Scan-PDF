import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:scanpdf/shared/models/enums.dart';

/// Parameters for one page-processing pass. Corners are normalized
/// (0..1) as [tlx, tly, trx, try, brx, bry, blx, bly]; null keeps the
/// full frame.
class ScanProcessRequest {
  const ScanProcessRequest({
    required this.bytes,
    this.corners,
    this.filter = ScanFilter.autoColor,
    this.rotationQuarters = 0,
    this.quality = 85,
    this.maxDimension = 2400,
  });

  final Uint8List bytes;
  final List<double>? corners;
  final ScanFilter filter;
  final int rotationQuarters;
  final int quality;
  final int maxDimension;
}

/// Image pipeline: decode → EXIF bake → perspective crop → rotate →
/// filter → resize cap → JPEG. Heavy work runs off the UI isolate.
class ScannerService {
  const ScannerService();

  Future<Uint8List> process(ScanProcessRequest request) =>
      compute(_processSync, request);

  /// Book mode turns one spread into two ordered pages, trimming the center
  /// gutter and applying the selected cleanup filter to each half.
  Future<List<Uint8List>> processBook(ScanProcessRequest request) =>
      compute(_processBookSync, request);

  static List<Uint8List> _processBookSync(ScanProcessRequest request) {
    var source = img.decodeImage(request.bytes);
    if (source == null) throw const FormatException('Unsupported image data');
    source = img.bakeOrientation(source);
    final gutter = math.max(2, (source.width * 0.015).round());
    final mid = source.width ~/ 2;
    final left = img.copyCrop(
      source,
      x: 0,
      y: 0,
      width: math.max(32, mid - gutter),
      height: source.height,
    );
    final right = img.copyCrop(
      source,
      x: math.min(source.width - 32, mid + gutter),
      y: 0,
      width: math.max(32, source.width - mid - gutter),
      height: source.height,
    );
    Uint8List finish(img.Image page) {
      page = _applyFilter(page, request.filter);
      final longest = math.max(page.width, page.height);
      if (longest > request.maxDimension) {
        final scale = request.maxDimension / longest;
        page = img.copyResize(
          page,
          width: (page.width * scale).round(),
          height: (page.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }
      return img.encodeJpg(page, quality: request.quality);
    }

    return [finish(left), finish(right)];
  }

  static Uint8List _processSync(ScanProcessRequest request) {
    var image = img.decodeImage(request.bytes);
    if (image == null) {
      throw const FormatException('Unsupported image data');
    }
    image = img.bakeOrientation(image);

    final corners = normalizedCorners(request.corners);
    if (corners != null) {
      image = _rectify(image, corners);
    }

    if (request.rotationQuarters % 4 != 0) {
      image = img.copyRotate(
        image,
        angle: 90.0 * (request.rotationQuarters % 4),
      );
    }

    image = _applyFilter(image, request.filter);

    final longest = math.max(image.width, image.height);
    if (longest > request.maxDimension) {
      final scale = request.maxDimension / longest;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    return img.encodeJpg(image, quality: request.quality);
  }

  /// Returns a safe normalized TL/TR/BR/BL quadrilateral, or null when
  /// a malformed/self-crossing crop should fall back to the full image.
  @visibleForTesting
  static List<double>? normalizedCorners(List<double>? input) {
    if (input == null || input.length != 8 || input.any((v) => !v.isFinite)) {
      return null;
    }
    final c = [for (final value in input) value.clamp(0.0, 1.0).toDouble()];
    final tl = math.Point<double>(c[0], c[1]);
    final tr = math.Point<double>(c[2], c[3]);
    final br = math.Point<double>(c[4], c[5]);
    final bl = math.Point<double>(c[6], c[7]);

    if (tl.x >= tr.x || bl.x >= br.x || tl.y >= bl.y || tr.y >= br.y) {
      return null;
    }
    final twiceArea =
        (tl.x * tr.y - tr.x * tl.y) +
        (tr.x * br.y - br.x * tr.y) +
        (br.x * bl.y - bl.x * br.y) +
        (bl.x * tl.y - tl.x * bl.y);
    if (twiceArea.abs() < 0.04) return null;
    return c;
  }

  static img.Image _rectify(img.Image src, List<double> c) {
    final w = src.width.toDouble();
    final h = src.height.toDouble();
    img.Point p(int i) => img.Point(c[i * 2] * w, c[i * 2 + 1] * h);
    final tl = p(0), tr = p(1), br = p(2), bl = p(3);

    double dist(img.Point a, img.Point b) {
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      return math.sqrt(dx * dx + dy * dy);
    }

    final outW = ((dist(tl, tr) + dist(bl, br)) / 2).round().clamp(32, 6000);
    final outH = ((dist(tl, bl) + dist(tr, br)) / 2).round().clamp(32, 6000);

    return img.copyRectify(
      src,
      topLeft: tl,
      topRight: tr,
      bottomRight: br,
      bottomLeft: bl,
      toImage: img.Image(width: outW, height: outH),
    );
  }

  static img.Image _applyFilter(img.Image src, ScanFilter filter) {
    switch (filter) {
      case ScanFilter.original:
        return src;
      case ScanFilter.autoColor:
        return img.adjustColor(
          src,
          contrast: 1.15,
          saturation: 1.1,
          brightness: 1.02,
        );
      case ScanFilter.blackWhite:
        return img.luminanceThreshold(src, threshold: 0.55);
      case ScanFilter.grayscale:
        return img.grayscale(src);
      case ScanFilter.lighten:
        return img.adjustColor(src, brightness: 1.18, gamma: 0.9);
      case ScanFilter.highContrast:
        return img.adjustColor(src, contrast: 1.45, saturation: 0.9);
    }
  }
}
