// 웹 전용: Web Speech API
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class SpeechController {
  js.JsObject? _recognition;

  void Function(String)? onResult;
  void Function(String)? onPartial;
  void Function(String)? onError;
  void Function()? onEnd;

  bool _aborted = false; // stop()으로 중단했을 때만 true

  Future<bool> initialize() async {
    return js.context.hasProperty('SpeechRecognition') ||
        js.context.hasProperty('webkitSpeechRecognition');
  }

  /// 한 세션 시작. 완료(onend)되면 onEnd 콜백 호출.
  /// continuous=false: 한 발화 → onresult(isFinal) → onend
  void startSession({String lang = 'ko-KR'}) {
    _aborted = false;
    _destroyRecognition();

    final ctor = js.context.hasProperty('SpeechRecognition')
        ? 'SpeechRecognition'
        : 'webkitSpeechRecognition';

    final r = js.JsObject(js.context[ctor] as js.JsFunction);
    _recognition = r;

    r['lang'] = lang;
    r['continuous'] = false;       // 한 발화 단위
    r['interimResults'] = true;    // interim 즉시 전달
    r['maxAlternatives'] = 1;

    r['onresult'] = js.allowInterop((dynamic e) {
      if (_aborted) return;
      try {
        final results = e['results'] as js.JsObject;
        final len = results['length'] as int;
        if (len == 0) return;

        // 마지막 result만 읽으면 됨 (continuous=false: 항상 result[0])
        final last = results.callMethod('item', [len - 1]) as js.JsObject;
        final isFinal = last['isFinal'] as bool;
        final alt = last.callMethod('item', [0]) as js.JsObject;
        final text = (alt['transcript'] as String? ?? '').trim();
        if (text.isEmpty) return;

        if (isFinal) {
          onResult?.call(text);
        } else {
          onPartial?.call(text);
        }
      } catch (ex) {
        if (kDebugMode) debugPrint('[STT] onresult err: $ex');
      }
    });

    r['onerror'] = js.allowInterop((dynamic e) {
      if (_aborted) return;
      final err = e['error']?.toString() ?? 'unknown';
      if (kDebugMode) debugPrint('[STT] onerror: $err');
      onError?.call(err);
    });

    r['onend'] = js.allowInterop((_) {
      if (_aborted) return;
      if (kDebugMode) debugPrint('[STT] onend');
      onEnd?.call();
    });

    try {
      r.callMethod('start', []);
    } catch (e) {
      if (kDebugMode) debugPrint('[STT] start err: $e');
      if (!_aborted) onError?.call(e.toString());
    }
  }

  /// 완전 중단. 이후 onend/onerror 무시.
  void abort() {
    _aborted = true;
    _destroyRecognition();
  }

  void _destroyRecognition() {
    if (_recognition != null) {
      try {
        _recognition!['onresult'] = null;
        _recognition!['onerror'] = null;
        _recognition!['onend'] = null;
        _recognition!.callMethod('abort', []);
      } catch (_) {}
      _recognition = null;
    }
  }
}
