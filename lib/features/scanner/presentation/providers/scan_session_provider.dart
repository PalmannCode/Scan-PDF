import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/features/scanner/domain/models/captured_page.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';

part 'scan_session_provider.g.dart';

@Riverpod(keepAlive: true)
class ScanSessionNotifier extends _$ScanSessionNotifier {
  @override
  ScanSession build() => const ScanSession();

  void start({CameraMode? mode, bool fromEvent = false}) {
    final settings = ref.read(settingsProvider);
    state = ScanSession(
      mode: mode ?? settings.defaultCameraMode,
      fromEvent: fromEvent,
    );
  }

  void setMode(CameraMode mode) => state = state.copyWith(mode: mode);

  void addCapture(String tempPath) {
    final settings = ref.read(settingsProvider);
    state = state.copyWith(
      pages: [
        ...state.pages,
        CapturedPage(tempPath: tempPath, filter: settings.defaultFilter),
      ],
    );
  }

  void updatePage(int index, CapturedPage page) {
    if (index < 0 || index >= state.pages.length) return;
    final pages = [...state.pages];
    pages[index] = page;
    state = state.copyWith(pages: pages);
  }

  void removePage(int index) {
    if (index < 0 || index >= state.pages.length) return;
    final pages = [...state.pages]..removeAt(index);
    state = state.copyWith(pages: pages);
  }

  void reorder(int from, int to) {
    if (from < 0 || from >= state.pages.length) return;
    final pages = [...state.pages];
    final moved = pages.removeAt(from);
    pages.insert(to.clamp(0, pages.length), moved);
    state = state.copyWith(pages: pages);
  }

  void clear() => state = const ScanSession();
}
