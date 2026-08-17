import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

class DocumentWorkflow {
  const DocumentWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;
  final List<String> steps;

  static const templates = <DocumentWorkflow>[
    DocumentWorkflow(
      id: 'scan_ocr_upload',
      name: 'Scan to Cloud',
      description: 'Recognize text, create a PDF, and upload a backup.',
      steps: ['Scan', 'OCR', 'Save PDF', 'Upload'],
    ),
    DocumentWorkflow(
      id: 'scan_sign_email',
      name: 'Sign and Send',
      description: 'Open a document for signing, then share the signed PDF.',
      steps: ['Scan', 'Sign', 'Email'],
    ),
    DocumentWorkflow(
      id: 'image_convert_pdf',
      name: 'Image to PDF',
      description: 'Convert imported images into a shareable PDF.',
      steps: ['Import image', 'Convert', 'Share PDF'],
    ),
    DocumentWorkflow(
      id: 'receipt_expense',
      name: 'Receipt to Expense',
      description: 'Recognize a receipt and open structured AI extraction.',
      steps: ['Scan receipt', 'OCR', 'Extract fields'],
    ),
  ];
}

final workflowStoreProvider = Provider<WorkflowStore>(
  (ref) => WorkflowStore(ref.watch(prefsBoxProvider)),
);

class WorkflowStore {
  WorkflowStore(this._prefs);

  final Box<String> _prefs;
  static const _key = 'enabled_workflows';

  Set<String> enabledIds() {
    try {
      final raw = jsonDecode(_prefs.get(_key) ?? '[]') as List<dynamic>;
      return raw.cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  bool isEnabled(String id) => enabledIds().contains(id);

  Future<void> setEnabled(DocumentWorkflow workflow, bool enabled) async {
    final ids = enabledIds();
    enabled ? ids.add(workflow.id) : ids.remove(workflow.id);
    await _prefs.put(_key, jsonEncode(ids.toList()..sort()));
    await _syncMetadata(workflow, enabled);
  }

  Future<void> _syncMetadata(DocumentWorkflow workflow, bool enabled) async {
    if (!AppConfig.hasSupabase || !BackendRuntime.supabaseReady) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('workflows').upsert({
      'user_id': user.id,
      'template_key': workflow.id,
      'name': workflow.name,
      'steps': workflow.steps,
      'is_enabled': enabled,
      'is_plus_only': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,template_key');
  }
}
