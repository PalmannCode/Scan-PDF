import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:scanpdf/core/utils/haptics.dart';

/// Platform-aware dialogs: Cupertino on iOS, Material elsewhere.
abstract class AdaptiveDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    if (destructive) Haptics.destructive();
    if (Platform.isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Single-field text prompt (new folder, rename…). Returns trimmed text
  /// or null when cancelled.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? initialValue,
    String placeholder = '',
    String confirmLabel = 'Save',
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? submitted;
    if (Platform.isIOS) {
      submitted = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    } else {
      final materialContext = context;
      if (!materialContext.mounted) {
        controller.dispose();
        return null;
      }
      submitted = await showDialog<String>(
        context: materialContext,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: placeholder),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
    }
    controller.dispose();
    final trimmed = submitted?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
