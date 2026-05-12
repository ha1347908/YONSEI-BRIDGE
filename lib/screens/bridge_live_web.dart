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

  // ★ 핵심: stop()이 명시적으로 호출됐는지 추적
  //    true면 onend/onerror에서 콜백 완전 차단
  bool _stoppedByUser = false;
  bool _isListening = false;

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
    if (kDebugMode) debugPrint('[STT-Web] available: $hasSTT');
    return hasSTT;
  }

  Future<void> listen({String lang = 'ko-KR'}) async {
    if (_isListening) return;

    // 이전 인스턴스 완전 정리
    _cleanupRecognition();

    _stoppedByUser = false;
    _isListening = true;

    final ctorName = js.context.hasProperty('SpeechRecognition')
        ? 'SpeechRecognition'
        : 'webkitSpeechRecognition';

    _recognition = js.JsObject(js.context[ctorName] as js.JsFunction);
    _recognition!['lang'] = lang;
    _recognition!['continuous'] = false;
    _recognition!['interimResults'] = true;
    _recognition!['maxAlternatives'] = 1;

    // onresult
    _recognition!['onresult'] = js.allowInterop((dynamic event) {
      if (_stoppedByUser) return;
      try {
        final results = event['results'] as js.JsObject;
        final length = results['length'] as int;
        if (length == 0) return;
        final last = results.callMethod('item', [length - 1]) as js.JsObject;
        final isFinal = last['isFinal'] as bool;
        final alt = last.callMethod('item', [0]) as js.JsObject;
        final transcript = (alt['transcript'] as String).trim();
        if (transcript.isEmpty) return;
        if (isFinal) {
          _onResult?.call(transcript);
        } else {
          _onPartial?.call(transcript);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[STT-Web] onresult error: $e');
      }
    });

    // onerror
    _recognition!['onerror'] = js.allowInterop((dynamic event) {
      if (_stoppedByUser) return; // ★ 사용자가 중지한 경우 완전 무시
      final err = event['error']?.toString() ?? 'unknown';
      if (kDebugMode) debugPrint('[STT-Web] onerror: $err');
      _isListening = false;
      _onError?.call(err);
    });

    // onend
    _recognition!['onend'] = js.allowInterop((_) {
      if (_stoppedByUser) return; // ★ 사용자가 중지한 경우 완전 무시
      if (kDebugMode) debugPrint('[STT-Web] onend (natural)');
      _isListening = false;
      _onEnd?.call(); // 자연 종료일 때만 상위에 알림
    });

    try {
      _recognition!.callMethod('start', []);
    } catch (e) {
      if (kDebugMode) debugPrint('[STT-Web] start error: $e');
      _isListening = false;
      if (!_stoppedByUser) _onError?.call(e.toString());
    }
  }

  /// 사용자가 명시적으로 중지 (onend/onerror 콜백 차단)
  Future<void> stop() async {
    _stoppedByUser = true; // ★ 먼저 플래그 설정
    _isListening = false;
    _cleanupRecognition();
  }

  void _cleanupRecognition() {
    if (_recognition != null) {
      try {
        // 이벤트 핸들러 제거 후 stop
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
