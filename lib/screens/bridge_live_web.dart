// 웹 전용: Web Speech API (webkitSpeechRecognition / SpeechRecognition)
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// 웹에서 Web Speech API를 래핑하는 컨트롤러
class SpeechController {
  js.JsObject? _recognition;

  void Function(String)? _onResult;
  void Function(String)? _onPartial;
  void Function(String)? _onError;
  void Function()? _onEnd;

  bool _stoppedByUser = false;
  bool _isListening = false;

  // continuous=true에서 results는 누적됨
  // 이미 final 처리한 마지막 인덱스를 추적
  int _lastFinalIndex = -1;

  Future<bool> initialize({
    void Function(String)? onResult,
    void Function(String)? onPartial,
    void Function(String)? onError,
    void Function()? onEnd,
  }) async {
    _onResult = onResult;
    _onPartial = onPartial;
    _onError = onError;
    _onEnd = onEnd;

    final hasSTT = js.context.hasProperty('SpeechRecognition') ||
        js.context.hasProperty('webkitSpeechRecognition');
    return hasSTT;
  }

  Future<void> listen({String lang = 'ko-KR'}) async {
    if (_isListening) return;
    _cleanupRecognition();

    _stoppedByUser = false;
    _isListening = true;
    _lastFinalIndex = -1; // ★ 세션마다 초기화

    final ctorName = js.context.hasProperty('SpeechRecognition')
        ? 'SpeechRecognition'
        : 'webkitSpeechRecognition';

    _recognition = js.JsObject(js.context[ctorName] as js.JsFunction);
    _recognition!['lang'] = lang;
    _recognition!['continuous'] = true;
    _recognition!['interimResults'] = true;
    _recognition!['maxAlternatives'] = 1;

    _recognition!['onresult'] = js.allowInterop((dynamic event) {
      if (_stoppedByUser) return;
      try {
        final results = event['results'] as js.JsObject;
        final length = results['length'] as int;
        if (length == 0) return;

        // ★ 핵심: _lastFinalIndex+1 부터만 처리 (이전 final 재처리 방지)
        String interimTranscript = '';

        for (int i = _lastFinalIndex + 1; i < length; i++) {
          final result = results.callMethod('item', [i]) as js.JsObject;
          final isFinal = result['isFinal'] as bool;
          final alt = result.callMethod('item', [0]) as js.JsObject;
          final transcript = (alt['transcript'] as String? ?? '').trim();
          if (transcript.isEmpty) continue;

          if (isFinal) {
            _lastFinalIndex = i; // ★ 처리된 final 인덱스 업데이트
            _onResult?.call(transcript);
          } else {
            interimTranscript = transcript; // 마지막 interim만 사용
          }
        }

        if (interimTranscript.isNotEmpty) {
          _onPartial?.call(interimTranscript);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[STT-Web] onresult error: $e');
      }
    });

    _recognition!['onerror'] = js.allowInterop((dynamic event) {
      if (_stoppedByUser) return;
      final err = event['error']?.toString() ?? 'unknown';
      if (kDebugMode) debugPrint('[STT-Web] onerror: $err');
      _isListening = false;
      _onError?.call(err);
    });

    _recognition!['onend'] = js.allowInterop((_) {
      if (_stoppedByUser) return;
      if (kDebugMode) debugPrint('[STT-Web] onend');
      _isListening = false;
      _onEnd?.call();
    });

    try {
      _recognition!.callMethod('start', []);
    } catch (e) {
      if (kDebugMode) debugPrint('[STT-Web] start error: $e');
      _isListening = false;
      if (!_stoppedByUser) _onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    _stoppedByUser = true;
    _isListening = false;
    _cleanupRecognition();
  }

  void _cleanupRecognition() {
    if (_recognition != null) {
      try {
        _recognition!['onresult'] = null;
        _recognition!['onerror'] = null;
        _recognition!['onend'] = null;
        _recognition!['onnomatch'] = null;
        _recognition!.callMethod('abort', []);
      } catch (_) {}
      _recognition = null;
    }
  }
}
