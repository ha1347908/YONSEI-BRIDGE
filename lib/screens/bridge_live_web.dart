// 웹 전용: Web Speech API (webkitSpeechRecognition / SpeechRecognition)
// dart:html을 직접 사용하여 브라우저 음성인식 API 호출
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// 웹에서 Web Speech API를 래핑하는 컨트롤러
class SpeechController {
  js.JsObject? _recognition;

  void Function(String)? _onResult;
  void Function(String)? _onPartial;
  void Function(String)? _onError;
  void Function()? _onEnd;

  bool _isListening = false;

  /// 초기화: SpeechRecognition 지원 여부 확인
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

    // SpeechRecognition or webkitSpeechRecognition 지원 여부 확인
    final hasSTT = js.context.hasProperty('SpeechRecognition') ||
        js.context.hasProperty('webkitSpeechRecognition');

    if (kDebugMode) debugPrint('[BridgeLive Web] SpeechRecognition available: $hasSTT');
    return hasSTT;
  }

  /// 음성 인식 시작
  Future<void> listen({String lang = 'ko-KR'}) async {
    if (_isListening) return;
    _isListening = true;

    // SpeechRecognition 객체 생성
    final ctorName = js.context.hasProperty('SpeechRecognition')
        ? 'SpeechRecognition'
        : 'webkitSpeechRecognition';

    _recognition = js.JsObject(js.context[ctorName] as js.JsFunction);

    // 설정
    _recognition!['lang'] = lang;
    _recognition!['continuous'] = false;      // false: 한 문장씩 (자동 재시작으로 지속)
    _recognition!['interimResults'] = true;   // 중간 결과 받기
    _recognition!['maxAlternatives'] = 1;

    // onresult: 인식 결과
    _recognition!['onresult'] = js.allowInterop((dynamic event) {
      try {
        final results = event['results'] as js.JsObject;
        final length = results['length'] as int;
        if (length == 0) return;

        final lastResult = results.callMethod('item', [length - 1]) as js.JsObject;
        final isFinal = lastResult['isFinal'] as bool;
        final alternatives = lastResult.callMethod('item', [0]) as js.JsObject;
        final transcript = alternatives['transcript'] as String;

        if (isFinal) {
          _onResult?.call(transcript.trim());
        } else {
          _onPartial?.call(transcript.trim());
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[BridgeLive Web] onresult error: $e');
      }
    });

    // onerror
    _recognition!['onerror'] = js.allowInterop((dynamic event) {
      final errorMsg = event['error']?.toString() ?? 'unknown';
      if (kDebugMode) debugPrint('[BridgeLive Web] onerror: $errorMsg');
      _isListening = false;
      _onError?.call(errorMsg);
    });

    // onend
    _recognition!['onend'] = js.allowInterop((_) {
      if (kDebugMode) debugPrint('[BridgeLive Web] onend');
      _isListening = false;
      _onEnd?.call();
    });

    // onnomatch
    _recognition!['onnomatch'] = js.allowInterop((_) {
      _isListening = false;
      _onEnd?.call();
    });

    try {
      _recognition!.callMethod('start', []);
    } catch (e) {
      if (kDebugMode) debugPrint('[BridgeLive Web] start error: $e');
      _isListening = false;
      _onError?.call(e.toString());
    }
  }

  /// 음성 인식 중지
  Future<void> stop() async {
    _isListening = false;
    try {
      _recognition?.callMethod('stop', []);
    } catch (_) {}
    _recognition = null;
  }
}
