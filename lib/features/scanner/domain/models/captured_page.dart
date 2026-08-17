import 'package:scanpdf/shared/models/enums.dart';

/// An in-session captured/imported page before it is persisted. Lives in
/// memory only; [tempPath] points at the camera/gallery temp file.
class CapturedPage {
  const CapturedPage({
    required this.tempPath,
    this.corners,
    this.filter = ScanFilter.autoColor,
    this.rotationQuarters = 0,
  });

  final String tempPath;

  /// Normalized crop quad [tlx, tly, trx, try, brx, bry, blx, bly];
  /// null keeps the full frame.
  final List<double>? corners;
  final ScanFilter filter;
  final int rotationQuarters;

  CapturedPage copyWith({
    List<double>? corners,
    bool clearCorners = false,
    ScanFilter? filter,
    int? rotationQuarters,
  }) => CapturedPage(
    tempPath: tempPath,
    corners: clearCorners ? null : (corners ?? this.corners),
    filter: filter ?? this.filter,
    rotationQuarters: rotationQuarters ?? this.rotationQuarters,
  );
}

/// The active scan/import batch (Jira §14 batch scan).
class ScanSession {
  const ScanSession({
    this.pages = const [],
    this.mode = CameraMode.document,
    this.fromEvent = false,
  });

  final List<CapturedPage> pages;
  final CameraMode mode;

  /// Started from the Receipt Rescue event CTA — a save during the live
  /// window counts toward the challenge.
  final bool fromEvent;

  bool get isEmpty => pages.isEmpty;

  ScanSession copyWith({
    List<CapturedPage>? pages,
    CameraMode? mode,
    bool? fromEvent,
  }) => ScanSession(
    pages: pages ?? this.pages,
    mode: mode ?? this.mode,
    fromEvent: fromEvent ?? this.fromEvent,
  );
}
