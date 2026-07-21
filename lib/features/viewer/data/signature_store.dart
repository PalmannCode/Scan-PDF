import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

  List<SavedSignature> getAll() {
    final raw = prefs.get(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedSignature.fromJson(e as Map<String, dynamic>))
          .toList();
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
    await prefs
        .put(_key, jsonEncode([for (final s in remaining) s.toJson()]));
  }
}
