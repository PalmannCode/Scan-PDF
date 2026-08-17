import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';

class QrResultScreen extends StatelessWidget {
  const QrResultScreen({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final uri = Uri.tryParse(value);
    final canOpen =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.go('/'),
          child: Icon(Icons.close_rounded, color: colors.textPrimary),
        ),
        title: Text('QR Code', style: AppTypography.title(colors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.qr_code_2_rounded, size: 72, color: colors.accent),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.paperCard,
                  borderRadius: AppShapes.cardRadius,
                ),
                child: SelectableText(
                  value,
                  style: AppTypography.body(colors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (canOpen)
                FilledButton.icon(
                  onPressed: () =>
                      launchUrl(uri, mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open link'),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
              TextButton.icon(
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: value)),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
