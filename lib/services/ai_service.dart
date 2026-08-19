import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';

enum AiAction { ask, summary, extract, translate, count }

/// Thrown when the free AI message quota is exhausted, so screens can show
/// the limit copy and surface the Plus paywall instead of a generic error.
class AiLimitReachedError extends StateError {
  AiLimitReachedError()
    : super(
        'Your free AI limit is used. Upgrade to Plus for continued access.',
      );
}

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
    final FunctionResponse response;
    try {
      response = await _client.functions
          .invoke(
            'ai_document_assistant',
            body: {
              'action': action.name,
              'text': ?text,
              'question': ?question,
              'target_language': ?targetLanguage,
              'image_data_url': ?imageDataUrl,
            },
          )
          // Without this the call can hang indefinitely and the caller sits on
          // a spinner with no way out.
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw StateError(
        'The AI service did not respond in time. Check your connection and try again.',
      );
    } on FunctionsHttpException catch (error) {
      // Non-2xx responses throw instead of returning a FunctionResponse;
      // `details` holds the decoded JSON body for application/json errors.
      final details = error.details;
      final serverError = details is Map ? details['error']?.toString() : null;
      if (serverError == 'AI_LIMIT_REACHED') {
        throw AiLimitReachedError();
      }
      if (serverError != null && serverError.isNotEmpty) {
        throw StateError(serverError);
      }
      rethrow;
    }
    final data = response.data;
    if (data is! Map) {
      throw StateError('The AI service returned an invalid response.');
    }
    if (data['error'] != null) {
      if (data['error'] == 'AI_LIMIT_REACHED') {
        throw AiLimitReachedError();
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
