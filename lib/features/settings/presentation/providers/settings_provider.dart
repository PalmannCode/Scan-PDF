import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/features/settings/data/app_state_repository.dart';
import 'package:scanpdf/shared/models/scan_settings.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
AppStateRepository appStateRepository(Ref ref) =>
    AppStateRepository(ref.watch(prefsBoxProvider));

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  ScanSettings build() =>
      ref.read(appStateRepositoryProvider).loadSettings();

  Future<void> update(ScanSettings Function(ScanSettings) transform) async {
    final next = transform(state);
    state = next;
    await ref.read(appStateRepositoryProvider).saveSettings(next);
  }
}

@Riverpod(keepAlive: true)
ThemeMode themeMode(Ref ref) {
  final mode = ref.watch(settingsProvider).themeMode;
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
