import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/services/cloud_sync_service.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// Prefs key recording which account this device's library was last synced
/// under. CloudSyncService refuses to upload under a different account so a
/// new sign-in cannot absorb the previous user's documents.
const String _lastSyncedUserIdKey = 'last_synced_user_id';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final prefs = ref.watch(prefsBoxProvider);
  return CloudSyncService(
    documents: ref.watch(documentRepositoryProvider),
    folders: ref.watch(folderRepositoryProvider),
    pdf: ref.watch(pdfServiceProvider),
    resolvePath: ref.watch(resolvePathProvider),
    deletionLog: ref.watch(deletionLogProvider),
    readLastSyncedUserId: () => prefs.get(_lastSyncedUserIdKey),
    writeLastSyncedUserId: (userId) => prefs.put(_lastSyncedUserIdKey, userId),
  );
});
