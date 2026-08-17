import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/features/home/domain/repositories/document_repository.dart';
import 'package:scanpdf/features/home/domain/repositories/folder_repository.dart';
import 'package:scanpdf/services/pdf_service.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';
import 'package:scanpdf/shared/models/scan_page.dart';
import 'package:scanpdf/shared/models/scan_settings.dart';

class SyncSummary {
  const SyncSummary({
    required this.uploaded,
    required this.restored,
    this.restoredSettings,
  });

  final int uploaded;
  final int restored;
  final ScanSettings? restoredSettings;
}

/// Local-first Supabase synchronizer. Remote object names always begin with
/// the authenticated user id, matching Storage RLS policies in the migration.
class CloudSyncService {
  CloudSyncService({
    required this.documents,
    required this.folders,
    required this.pdf,
    required this.resolvePath,
  });

  final DocumentRepository documents;
  final FolderRepository folders;
  final PdfService pdf;
  final String Function(String) resolvePath;

  SupabaseClient get _client {
    if (!AppConfig.hasSupabase || !BackendRuntime.supabaseReady) {
      throw StateError('Cloud services are not configured in this build.');
    }
    return Supabase.instance.client;
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in before using cloud sync.');
    return id;
  }

  Future<void> _requireNetwork() async {
    final results = await Connectivity().checkConnectivity();
    if (results.every((result) => result == ConnectivityResult.none)) {
      throw StateError('Cloud sync needs an internet connection.');
    }
  }

  Future<SyncSummary> syncLibrary(ScanSettings settings) async {
    await _requireNetwork();
    final userId = _userId;
    final remoteSettings = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    ScanSettings? restoredSettings;
    if (remoteSettings != null && settings == const ScanSettings()) {
      T enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
        return values.where((value) => value.name == name).firstOrNull ??
            fallback;
      }

      restoredSettings = settings.copyWith(
        defaultCameraMode: enumOr(
          CameraMode.values,
          remoteSettings['default_scan_mode'] as String?,
          settings.defaultCameraMode,
        ),
        defaultFilter: enumOr(
          ScanFilter.values,
          remoteSettings['default_filter'] as String?,
          settings.defaultFilter,
        ),
        autoCaptureEnabled:
            remoteSettings['auto_capture_enabled'] as bool? ??
            settings.autoCaptureEnabled,
        ocrLanguageBundle:
            remoteSettings['ocr_language_bundle'] as String? ??
            settings.ocrLanguageBundle,
        autoOcrAfterScan:
            remoteSettings['auto_ocr_enabled'] as bool? ??
            settings.autoOcrAfterScan,
        defaultExportFormat:
            remoteSettings['default_export_format'] as String? ??
            settings.defaultExportFormat,
        defaultFileNameFormat:
            remoteSettings['default_file_name_format'] as String? ??
            settings.defaultFileNameFormat,
        appIcon: remoteSettings['app_icon'] as String? ?? settings.appIcon,
        syncEnabled:
            remoteSettings['sync_enabled'] as bool? ?? settings.syncEnabled,
        autoUploadEnabled:
            remoteSettings['auto_upload_enabled'] as bool? ??
            settings.autoUploadEnabled,
        defaultEmailSubject:
            remoteSettings['default_email_subject'] as String? ??
            settings.defaultEmailSubject,
        defaultEmailBody:
            remoteSettings['default_email_body'] as String? ??
            settings.defaultEmailBody,
        defaultEmailSignature:
            remoteSettings['default_email_signature'] as String? ??
            settings.defaultEmailSignature,
        emailAttachmentFormat:
            remoteSettings['email_attachment_format'] as String? ??
            settings.emailAttachmentFormat,
        includeDocumentDate:
            remoteSettings['include_document_date'] as bool? ??
            settings.includeDocumentDate,
        diagnosticLogsEnabled:
            remoteSettings['diagnostic_logs_enabled'] as bool? ??
            settings.diagnosticLogsEnabled,
        createSearchablePdf:
            remoteSettings['create_searchable_pdf'] as bool? ??
            settings.createSearchablePdf,
      );
    }
    final localFolders = folders.getAll();
    if (localFolders.isNotEmpty) {
      await _client.from('folders').upsert([
        for (final folder in localFolders)
          {
            'id': folder.id,
            'user_id': userId,
            'name': folder.name,
            'created_at': folder.createdAt.toUtc().toIso8601String(),
            'updated_at': folder.modifiedAt.toUtc().toIso8601String(),
          },
      ]);
    }
    var uploaded = 0;
    for (final document in documents.getAll()) {
      await uploadDocument(document);
      uploaded++;
    }
    final effectiveSettings = restoredSettings ?? settings;
    await _client.from('user_settings').upsert({
      'user_id': userId,
      'default_scan_mode': effectiveSettings.defaultCameraMode.name,
      'default_filter': effectiveSettings.defaultFilter.name,
      'auto_capture_enabled': effectiveSettings.autoCaptureEnabled,
      'ocr_language_bundle': effectiveSettings.ocrLanguageBundle,
      'auto_ocr_enabled': effectiveSettings.autoOcrAfterScan,
      'default_export_format': effectiveSettings.defaultExportFormat,
      'default_file_name_format': effectiveSettings.defaultFileNameFormat,
      'app_icon': effectiveSettings.appIcon,
      'sync_enabled': effectiveSettings.syncEnabled,
      'auto_upload_enabled': effectiveSettings.autoUploadEnabled,
      'default_email_subject': effectiveSettings.defaultEmailSubject,
      'default_email_body': effectiveSettings.defaultEmailBody,
      'default_email_signature': effectiveSettings.defaultEmailSignature,
      'email_attachment_format': effectiveSettings.emailAttachmentFormat,
      'include_document_date': effectiveSettings.includeDocumentDate,
      'diagnostic_logs_enabled': effectiveSettings.diagnosticLogsEnabled,
      'create_searchable_pdf': effectiveSettings.createSearchablePdf,
    }, onConflict: 'user_id');
    final restored = await restoreNewerRemoteItems();
    return SyncSummary(
      uploaded: uploaded,
      restored: restored,
      restoredSettings: restoredSettings,
    );
  }

  Future<void> uploadDocument(ScanDocument document) async {
    await _requireNetwork();
    final userId = _userId;
    final root = '$userId/${document.id}';
    final pageRows = <Map<String, Object?>>[];
    final pdfImages = <List<int>>[];
    for (var index = 0; index < document.pages.length; index++) {
      final page = document.pages[index];
      final processed = await File(
        resolvePath(page.processedFileName),
      ).readAsBytes();
      List<int> original;
      try {
        original = await File(resolvePath(page.originalFileName)).readAsBytes();
      } catch (_) {
        original = processed;
      }
      final processedPath = '$root/${page.id}.jpg';
      final originalPath = '$root/${page.id}.jpg';
      await _client.storage
          .from('processed-pages')
          .uploadBinary(
            processedPath,
            processed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      await _client.storage
          .from('original-pages')
          .uploadBinary(
            originalPath,
            Uint8List.fromList(original),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      pdfImages.add(processed);
      pageRows.add({
        'id': page.id,
        'document_id': document.id,
        'page_index': index,
        'original_image_url': originalPath,
        'processed_image_url': processedPath,
        'local_original_path': page.originalFileName,
        'local_processed_path': page.processedFileName,
        'filter_type': page.filter.name,
        'ocr_text': page.ocrText,
      });
    }
    final pdfPath = '$root/document.pdf';
    if (pdfImages.isNotEmpty) {
      await _client.storage
          .from('scanned-documents')
          .uploadBinary(
            pdfPath,
            await pdf.buildPdf(
              [for (final bytes in pdfImages) Uint8List.fromList(bytes)],
              searchableText: [for (final page in document.pages) page.ocrText],
            ),
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    }
    await _client.from('documents').upsert({
      'id': document.id,
      'user_id': userId,
      'folder_id': document.folderId,
      'title': document.title,
      'thumbnail_url': document.pages.isEmpty
          ? null
          : '$root/${document.pages.first.id}.jpg',
      'pdf_url': pdfImages.isEmpty ? null : pdfPath,
      'file_type': 'scan',
      'page_count': document.pageCount,
      'full_ocr_text': document.ocrText,
      'is_synced': true,
      'cloud_provider': 'supabase',
      'created_at': document.createdAt.toUtc().toIso8601String(),
      'updated_at': document.modifiedAt.toUtc().toIso8601String(),
      'deleted_at': document.deletedAt?.toUtc().toIso8601String(),
    });
    if (pageRows.isNotEmpty) {
      await _client.from('document_pages').upsert(pageRows);
    }
  }

  Future<int> restoreNewerRemoteItems() async {
    final remoteFolders = await _client.from('folders').select();
    for (final row in remoteFolders) {
      final map = row;
      final existing = folders
          .getAll()
          .where((item) => item.id == map['id'])
          .firstOrNull;
      final modified = DateTime.parse(map['updated_at'] as String).toLocal();
      if (existing == null || existing.modifiedAt.isBefore(modified)) {
        await folders.upsert(
          ScanFolder(
            id: map['id'] as String,
            name: map['name'] as String,
            createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
            modifiedAt: modified,
          ),
        );
      }
    }
    final remoteDocs = await _client
        .from('documents')
        .select('*,document_pages(*)');
    var restored = 0;
    for (final row in remoteDocs) {
      final map = row;
      final id = map['id'] as String;
      final modified = DateTime.parse(map['updated_at'] as String).toLocal();
      final existing = documents.getById(id);
      if (existing != null && !existing.modifiedAt.isBefore(modified)) continue;
      final rows =
          (map['document_pages'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
            ..sort(
              (a, b) =>
                  (a['page_index'] as int).compareTo(b['page_index'] as int),
            );
      final pages = <ScanPage>[];
      for (final pageRow in rows) {
        final pageId = pageRow['id'] as String;
        final processed = await _client.storage
            .from('processed-pages')
            .download(pageRow['processed_image_url'] as String);
        List<int> original;
        try {
          original = await _client.storage
              .from('original-pages')
              .download(pageRow['original_image_url'] as String);
        } catch (_) {
          original = processed;
        }
        await documents.writePageFiles(
          pageId: pageId,
          processed: processed,
          original: Uint8List.fromList(original),
        );
        pages.add(
          ScanPage(
            id: pageId,
            filter: ScanFilter.values.byName(
              pageRow['filter_type'] as String? ?? 'autoColor',
            ),
            ocrText: pageRow['ocr_text'] as String? ?? '',
          ),
        );
      }
      await documents.upsert(
        ScanDocument(
          id: id,
          title: map['title'] as String,
          folderId: map['folder_id'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
          modifiedAt: modified,
          pages: pages,
          isDeleted: map['deleted_at'] != null,
          deletedAt: map['deleted_at'] == null
              ? null
              : DateTime.parse(map['deleted_at'] as String).toLocal(),
        ),
      );
      restored++;
    }
    return restored;
  }
}
