import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/services/cloud_sync_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>(
  (ref) => CloudSyncService(
    documents: ref.watch(documentRepositoryProvider),
    folders: ref.watch(folderRepositoryProvider),
    pdf: ref.watch(pdfServiceProvider),
    resolvePath: ref.watch(resolvePathProvider),
  ),
);
