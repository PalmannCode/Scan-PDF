import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';

enum AiAction { ask, summary, extract, translate, count }

class AiResponse {
  const AiResponse({required this.result, required this.used, this.limit});

  final Map<String, dynamic> result;
  final int used;
  final int? limit;
}

class AiService {
  SupabaseClient get _client {
    if (!AppConfig.hasSupabase || !BackendRuntime.supabaseReady) {
      throw StateError('AI needs a configured Supabase backend.');
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      throw StateError('Sign in before using AI tools.');
    }
    return Supabase.instance.client;
  }

  Future<AiResponse> run({
    required AiAction action,
    String? text,
    String? question,
    String? targetLanguage,
    String? imagePath,
  }) async {
    String? imageDataUrl;
    if (imagePath != null) {
      final bytes = await File(imagePath).readAsBytes();
      imageDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final response = await _client.functions.invoke(
      'ai_document_assistant',
      body: {
        'action': action.name,
        'text': ?text,
        'question': ?question,
        'target_language': ?targetLanguage,
        'image_data_url': ?imageDataUrl,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw StateError('The AI service returned an invalid response.');
    }
    if (data['error'] != null) {
      if (data['error'] == 'AI_LIMIT_REACHED') {
        throw StateError(
          'Your free AI limit is used. Upgrade to Plus for continued access.',
        );
      }
      throw StateError(data['error'].toString());
    }
    final usage = data['usage'] as Map? ?? const {};
    return AiResponse(
      result: Map<String, dynamic>.from(data['result'] as Map),
      used: usage['used'] as int? ?? 0,
      limit: usage['limit'] as int?,
    );
  }
}
