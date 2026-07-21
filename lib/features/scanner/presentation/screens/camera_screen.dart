import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/haptics.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/error_view.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';
import 'package:scanpdf/features/home/presentation/providers/import_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_session_provider.dart';
import 'package:scanpdf/features/scanner/presentation/widgets/camera_controls.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _initializing = true;
  bool _capturing = false;
  bool _showFilters = false;
  bool _flashFeedback = false;
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
    });
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _permissionDenied = e.code.contains('AccessDenied');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() {
      _capturing = true;
      _flashFeedback = true;
    });
    try {
      final shot = await controller.takePicture();
      Haptics.success();
      final session = ref.read(scanSessionProvider.notifier);
      session.addCapture(shot.path);
      final pages = ref.read(scanSessionProvider).pages;
      session.updatePage(
        pages.length - 1,
        pages.last.copyWith(filter: _filter),
      );
    } on CameraException {
      // Capture failed; the shutter simply stays available.
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        Future<void>.delayed(AppMotion.micro, () {
          if (mounted) setState(() => _flashFeedback = false);
        });
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
        message:
            '${session.pages.length} captured page(s) will be discarded.',
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
                onSelected: (f) => setState(() {
                  _filter = f;
                  _showFilters = false;
                }),
              ),
            CameraModeBar(
              mode: session.mode,
              filter: _filter,
              onMode: (m) =>
                  ref.read(scanSessionProvider.notifier).setMode(m),
              onFilterTap: () =>
                  setState(() => _showFilters = !_showFilters),
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
        subtitle:
            'Allow camera access in Settings to scan paper documents.',
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
            ColoredBox(
              color: colors.shellBg.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }
}
