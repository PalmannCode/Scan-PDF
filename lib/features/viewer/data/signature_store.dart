import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';

/// Saved, reusable signatures — THE Plus-gated convenience. Free users
/// draw a signature each time; Plus users keep a library of them.
/// PNG files live under `signatures/`, the index in the prefs box.
class SavedSignature {
  const SavedSignature({required this.id, required this.name});

  final String id;
  final String name;

  String get fileName => 'signatures/$id.png';

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory SavedSignature.fromJson(Map<String, dynamic> json) =>
      SavedSignature(id: json['id'] as String, name: json['name'] as String);
}

class SignatureStore {
  SignatureStore({required this.prefs, required this.resolvePath});

  final Box<String> prefs;
  final String Function(String relative) resolvePath;

  static const _key = 'saved_signatures';
  static const _defaultKey = 'default_signature_id';

  String? get defaultId => prefs.get(_defaultKey);

  bool isDefault(String id) => defaultId == id;

  List<SavedSignature> getAll() {
    final raw = prefs.get(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final signatures = list
          .map((e) => SavedSignature.fromJson(e as Map<String, dynamic>))
          .toList();
      final preferred = defaultId;
      signatures.sort((a, b) {
        if (a.id == preferred) return -1;
        if (b.id == preferred) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return signatures;
    } catch (_) {
      return const [];
    }
  }

  Future<SavedSignature> save(Uint8List png, String name) async {
    final signature = SavedSignature(id: const Uuid().v4(), name: name);
    final file = File(resolvePath(signature.fileName));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(png, flush: true);
    final all = [...getAll(), signature];
    await prefs.put(_key, jsonEncode([for (final s in all) s.toJson()]));
    await _upload(signature, png);
    return signature;
  }

  Future<Uint8List> read(SavedSignature signature) =>
      File(resolvePath(signature.fileName)).readAsBytes();

  Future<void> delete(String id) async {
    final all = getAll();
    final remaining = all.where((s) => s.id != id).toList();
    final removed = all.where((s) => s.id == id);
    for (final signature in removed) {
      final file = File(resolvePath(signature.fileName));
      if (file.existsSync()) file.deleteSync();
    }
    await prefs.put(_key, jsonEncode([for (final s in remaining) s.toJson()]));
    if (defaultId == id) await prefs.delete(_defaultKey);
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        await client.storage.from('signatures').remove(['${user.id}/$id.png']);
        await client.from('signatures').delete().eq('id', id);
      } catch (_) {
        // The local library remains authoritative while offline.
      }
    }
  }

  Future<void> rename(String id, String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    final renamed = [
      for (final signature in getAll())
        signature.id == id
            ? SavedSignature(id: signature.id, name: cleaned)
            : signature,
    ];
    await prefs.put(_key, jsonEncode([for (final s in renamed) s.toJson()]));
    final client = _clientOrNull;
    if (client?.auth.currentUser != null) {
      try {
        await client!.from('signatures').update({'name': cleaned}).eq('id', id);
      } catch (_) {}
    }
  }

  Future<void> setDefault(String id) async {
    if (!getAll().any((signature) => signature.id == id)) return;
    await prefs.put(_defaultKey, id);
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        await client
            .from('signatures')
            .update({'is_default': false})
            .eq('user_id', user.id);
        await client
            .from('signatures')
            .update({'is_default': true})
            .eq('id', id);
      } catch (_) {}
    }
  }

  SupabaseClient? get _clientOrNull =>
      AppConfig.hasSupabase && BackendRuntime.supabaseReady
      ? Supabase.instance.client
      : null;

  Future<void> _upload(SavedSignature signature, Uint8List png) async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      final path = '${user.id}/${signature.id}.png';
      await client.storage
          .from('signatures')
          .uploadBinary(
            path,
            png,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      await client.from('signatures').upsert({
        'id': signature.id,
        'user_id': user.id,
        'name': signature.name,
        'image_url': path,
        'local_path': signature.fileName,
        'is_default': isDefault(signature.id),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // A later manual cloud sync retries without invalidating the local save.
    }
  }

  Future<void> syncCloud() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    for (final signature in getAll()) {
      try {
        await _upload(signature, await read(signature));
      } catch (_) {}
    }
    final remote = await client
        .from('signatures')
        .select()
        .eq('user_id', user.id);
    final merged = {for (final item in getAll()) item.id: item};
    for (final row in remote) {
      final id = row['id'] as String;
      if (!merged.containsKey(id)) {
        final path = row['image_url'] as String;
        final png = await client.storage.from('signatures').download(path);
        final signature = SavedSignature(id: id, name: row['name'] as String);
        final file = File(resolvePath(signature.fileName));
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(png, flush: true);
        merged[id] = signature;
      }
      if (row['is_default'] == true) await prefs.put(_defaultKey, id);
    }
    await prefs.put(
      _key,
      jsonEncode([for (final item in merged.values) item.toJson()]),
    );
  }
}
