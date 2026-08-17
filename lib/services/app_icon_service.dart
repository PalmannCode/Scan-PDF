import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appIconServiceProvider = Provider<AppIconService>(
  (ref) => const AppIconService(),
);

class AppIconOption {
  const AppIconOption({
    required this.id,
    required this.label,
    required this.assetPath,
    this.nativeName,
    this.plusOnly = false,
  });

  final String id;
  final String label;
  final String assetPath;
  final String? nativeName;
  final bool plusOnly;
}

class AppIconService {
  const AppIconService();

  static const _channel = MethodChannel('scanpdf/app_icon');

  static const options = <AppIconOption>[
    AppIconOption(
      id: 'default',
      label: 'Default',
      assetPath: 'assets/icon.png',
    ),
    AppIconOption(
      id: 'dark',
      label: 'Dark',
      assetPath: 'assets/app_icons/icon_dark.png',
      nativeName: 'IconDark',
    ),
    AppIconOption(
      id: 'orange',
      label: 'Orange Camera',
      assetPath: 'assets/app_icons/icon_orange.png',
      nativeName: 'IconOrange',
    ),
    AppIconOption(
      id: 'minimal',
      label: 'Minimal',
      assetPath: 'assets/app_icons/icon_minimal.png',
      nativeName: 'IconMinimal',
    ),
    AppIconOption(
      id: 'plus',
      label: 'Plus',
      assetPath: 'assets/app_icons/icon_plus.png',
      nativeName: 'IconPlus',
      plusOnly: true,
    ),
  ];

  Future<void> setIcon(AppIconOption option) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Alternate app icons are available on iPhone.');
    }
    await _channel.invokeMethod<void>('setAlternateIcon', {
      'name': option.nativeName ?? '',
    });
  }
}
