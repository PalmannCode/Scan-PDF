import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/error_view.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';
import 'package:scanpdf/features/home/presentation/providers/import_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/scanner/presentation/widgets/camera_controls.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/services/qr_provider.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class _PreviewFrame {
  const _PreviewFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rowStride,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int rowStride;
}

Uint8List _encodePreviewFrame(_PreviewFrame frame) {
  final image = img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.bytes.buffer,
    rowStride: frame.rowStride,
    order: img.ChannelOrder.bgra,
  );
  final resized = frame.width > 720 ? img.copyResize(image, width: 720) : image;
  return img.encodeJpg(resized, quality: 72);
}

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _cameraUnavailable = false;
  bool _initializing = true;
  bool _capturing = false;
  bool _showFilters = false;
  bool _flashFeedback = false;
  bool _autoCaptureActive = false;
  bool _analyzingPreview = false;
  int _stableDocumentFrames = 0;
  DateTime _lastPreviewAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
  late ScanFilter _filter;
  late FlashMode _flash;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = ref.read(settingsProvider);
    _filter = settings.defaultFilter;
    _flash = settings.flashAuto ? FlashMode.auto : FlashMode.off;
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _permissionDenied = false;
      _cameraUnavailable = false;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      await _updateAutoCapture();
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _permissionDenied = e.code.contains('AccessDenied');
        _cameraUnavailable = !_permissionDenied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraUnavailable = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed &&
        (controller == null || !controller.value.isInitialized)) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  bool get _supportsAutoCaptureMode {
    final mode = ref.read(scanSessionProvider).mode;
    return mode == CameraMode.document ||
        mode == CameraMode.text ||
        mode == CameraMode.book;
  }

  Future<void> _updateAutoCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final enabled =
        Platform.isIOS &&
        ref.read(settingsProvider).autoCaptureEnabled &&
        _supportsAutoCaptureMode;
    if (!enabled) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      if (mounted) setState(() => _autoCaptureActive = false);
      return;
    }
    if (!controller.value.isStreamingImages) {
      try {
        await controller.startImageStream(_analyzePreview);
        if (mounted) setState(() => _autoCaptureActive = true);
      } on CameraException {
        if (mounted) setState(() => _autoCaptureActive = false);
      }
    }
  }

  Future<void> _analyzePreview(CameraImage frame) async {
    final now = DateTime.now();
    if (_analyzingPreview ||
        _capturing ||
        now.difference(_lastPreviewAnalysis) <
            const Duration(milliseconds: 850) ||
        frame.planes.isEmpty ||
        frame.format.group != ImageFormatGroup.bgra8888) {
      return;
    }
    _analyzingPreview = true;
    _lastPreviewAnalysis = now;
    File? previewFile;
    try {
      final plane = frame.planes.first;
      final bytes = await compute(
        _encodePreviewFrame,
        _PreviewFrame(
          bytes: Uint8List.fromList(plane.bytes),
          width: frame.width,
          height: frame.height,
          rowStride: plane.bytesPerRow,
        ),
      );
      final temp = await getTemporaryDirectory();
      previewFile = File('${temp.path}/scanpdf_auto_preview.jpg');
      await previewFile.writeAsBytes(bytes, flush: true);
      final corners = await ref
          .read(ocrServiceProvider)
          .detectDocumentCorners(previewFile.path);
      final stable = corners != null && _quadrilateralArea(corners) >= 0.24;
      _stableDocumentFrames = stable ? _stableDocumentFrames + 1 : 0;
      if (_stableDocumentFrames >= 2 && mounted && !_capturing) {
        _stableDocumentFrames = 0;
        await ref
            .read(analyticsServiceProvider)
            .track(
              'auto_capture_triggered',
              properties: {
                'tool_name': ref.read(scanSessionProvider).mode.name,
              },
            );
        await _capture(autoTriggered: true);
      }
    } catch (_) {
      _stableDocumentFrames = 0;
    } finally {
      if (previewFile?.existsSync() ?? false) {
        await previewFile!.delete();
      }
      _analyzingPreview = false;
    }
  }

  double _quadrilateralArea(List<double> points) {
    if (points.length != 8) return 0;
    var area = 0.0;
    for (var i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      area += points[i * 2] * points[next * 2 + 1];
      area -= points[next * 2] * points[i * 2 + 1];
    }
    return area.abs() / 2;
  }

  Future<void> _capture({bool autoTriggered = false}) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() {
      _capturing = true;
      _flashFeedback = true;
    });
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final shot = await controller.takePicture();
      Haptics.success();
      final mode = ref.read(scanSessionProvider).mode;
      if (mode == CameraMode.qrCode) {
        final value = await ref.read(qrServiceProvider).scanFile(shot.path);
        if (!mounted) return;
        if (value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code was found. Hold steady and try again.'),
            ),
          );
          return;
        }
        ref.read(scanSessionProvider.notifier).clear();
        context.pushReplacement(
          '/qr-result?value=${Uri.encodeComponent(value)}',
        );
        return;
      }
      if (mode == CameraMode.measure ||
          mode == CameraMode.count ||
          mode == CameraMode.translate) {
        ref.read(scanSessionProvider.notifier).clear();
        final route = switch (mode) {
          CameraMode.measure => '/measure',
          CameraMode.count => '/count',
          _ => '/translate',
        };
        if (mounted) context.pushReplacement(route, extra: shot.path);
        return;
      }
      List<double>? corners;
      if (mode == CameraMode.document || mode == CameraMode.text) {
        try {
          corners = await ref
              .read(ocrServiceProvider)
              .detectDocumentCorners(shot.path);
        } catch (_) {
          // Manual crop remains available when automatic detection cannot run.
        }
      }
      final session = ref.read(scanSessionProvider.notifier);
      session.addCapture(shot.path, corners: corners);
      final pages = ref.read(scanSessionProvider).pages;
      session.updatePage(
        pages.length - 1,
        pages.last.copyWith(filter: _filter),
      );
      if (autoTriggered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document captured automatically.')),
        );
      }
    } on CameraException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The photo could not be captured. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        Future<void>.delayed(AppMotion.micro, () {
          if (mounted) setState(() => _flashFeedback = false);
        });
        await _updateAutoCapture();
      }
    }
  }

  Future<void> _cycleFlash() async {
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    setState(() => _flash = next);
    try {
      await _controller?.setFlashMode(next);
    } on CameraException {
      // Some devices reject certain modes; the UI state still cycles.
    }
  }

  Future<void> _close() async {
    final session = ref.read(scanSessionProvider);
    if (session.pages.isNotEmpty) {
      final ok = await AdaptiveDialog.confirm(
        context,
        title: 'Discard scans?',
        message: '${session.pages.length} captured page(s) will be discarded.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!ok) return;
      ref.read(scanSessionProvider.notifier).clear();
    }
    if (mounted) context.pop();
  }

  Future<void> _importFromGallery() async {
    final before = ref.read(scanSessionProvider).pages.length;
    final picked = await ref
        .read(importControllerProvider)
        .importPhotosIntoCurrentSession();
    if (picked > 0 && mounted) {
      final total = before + picked;
      if (total > 0) context.pushReplacement('/review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            CameraTopBar(
              flash: _flash,
              pageCount: session.pages.length,
              onClose: _close,
              onFlash: _cycleFlash,
              onBatchTap: () => context.pushReplacement('/review'),
            ),
            Expanded(child: _buildPreview()),
            if (_showFilters)
              FilterChipsRow(
                selected: _filter,
                onSelected: (f) {
                  if (f.isPlus && !ref.read(plusProvider).isActive) {
                    context.push('/paywall');
                    return;
                  }
                  setState(() {
                    _filter = f;
                    _showFilters = false;
                  });
                },
              ),
            CameraModeBar(
              mode: session.mode,
              filter: _filter,
              onMode: (m) async {
                ref.read(scanSessionProvider.notifier).setMode(m);
                await _updateAutoCapture();
              },
              onFilterTap: () => setState(() => _showFilters = !_showFilters),
            ),
            CameraShutterBar(
              capturing: _capturing,
              hasPages: session.pages.isNotEmpty,
              onShutter: _capture,
              onGallery: _importFromGallery,
              onDone: () => context.pushReplacement('/review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final colors = context.colors;
    if (_permissionDenied) {
      return ErrorView(
        onShell: true,
        title: 'Camera access needed',
        subtitle: 'Allow camera access in Settings to scan paper documents.',
        onRetry: _initCamera,
      );
    }
    if (_cameraUnavailable) {
      return ErrorView(
        onShell: true,
        title: 'Camera unavailable',
        subtitle:
            'The camera could not be started. You can retry or import a photo instead.',
        onRetry: _initCamera,
      );
    }
    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 180,
          height: 240,
          child: ScanPulseFrame(child: SizedBox.expand()),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            child: CameraPreview(controller),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ScanPulseFrame(
              animated: !_capturing,
              strokeWidth: 3,
              child: const SizedBox.expand(),
            ),
          ),
          AnimatedOpacity(
            opacity: _flashFeedback ? 0.75 : 0,
            duration: AppMotion.micro,
            child: const ColoredBox(color: Colors.white),
          ),
          if (_capturing)
            ColoredBox(color: colors.shellBg.withValues(alpha: 0.2)),
          if (_autoCaptureActive)
            Positioned(
              top: AppSpacing.md,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: const BorderRadius.all(Radius.circular(99)),
                  ),
                  child: const Text(
                    'AUTO · HOLD STEADY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
