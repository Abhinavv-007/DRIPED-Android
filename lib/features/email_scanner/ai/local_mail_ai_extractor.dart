import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mail_ai_models.dart';

class LocalMailAiExtractor {
  LocalMailAiExtractor._();

  static final LocalMailAiExtractor instance = LocalMailAiExtractor._();
  static const MethodChannel _channel = MethodChannel('driped/local_mail_ai');

  bool? _available;

  Future<bool> isAvailable({bool refresh = false}) async {
    if (!refresh && _available != null) return _available!;
    try {
      final value = await _channel.invokeMethod<bool>('isAvailable');
      return _available = value ?? false;
    } on MissingPluginException {
      return _available = false;
    } on PlatformException catch (error) {
      debugPrint('[LocalAI] Availability check failed: ${error.message}');
      return _available = false;
    } catch (error) {
      debugPrint('[LocalAI] Availability check failed: $error');
      return _available = false;
    }
  }

  Future<AiMailExtraction?> extract(MailAiInput input) async {
    try {
      final raw = await _channel.invokeMethod<Object>(
          'extractSubscription', input.toMap());
      final map = _decodeResult(raw);
      if (map == null) return null;
      return AiMailExtraction.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      if (error.code != 'MODEL_UNAVAILABLE') {
        debugPrint(
            '[LocalAI] Extraction failed: ${error.code}: ${error.message}');
      }
      return null;
    } catch (error) {
      debugPrint('[LocalAI] Extraction failed: $error');
      return null;
    }
  }

  Future<void> release() async {
    try {
      await _channel.invokeMethod<bool>('release');
    } catch (_) {}
  }

  Map<String, dynamic>? _decodeResult(Object? raw) {
    try {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      debugPrint('[LocalAI] Model returned invalid JSON: $error');
    }
    return null;
  }
}
