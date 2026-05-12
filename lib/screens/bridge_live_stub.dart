// 네이티브(Android/iOS) 전용: speech_to_text 패키지 사용
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// 네이티브에서 speech_to_text를 래핑하는 컨트롤러
class SpeechController {
  final stt.SpeechToText _speech = stt.SpeechToText();

  void Function(String)? _onResult;
  void Function(String)? _onPartial;
  void Function(String)? _onError;
  void Function()? _onEnd;

  static const Duration _listenFor = Duration(seconds: 30);
  static const Duration _pauseFor = Duration(seconds: 3);

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

    // 권한 상태만 확인 (실제 요청은 STT가 처리)
    final permStatus = await Permission.microphone.status;
    if (permStatus.isPermanentlyDenied) return false;

    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
        finalTimeout: const Duration(milliseconds: 2000),
      );
      if (!available) {
        // 1회 재시도
        await Future.delayed(const Duration(milliseconds: 800));
        return await _speech.initialize(
          onStatus: _onStatus,
          onError: _onSpeechError,
        );
      }
      return available;
    } catch (e) {
      if (kDebugMode) debugPrint('[BridgeLive Native] init error: $e');
      return false;
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) debugPrint('[BridgeLive Native] status: $status');
    if (status == 'done' || status == 'notListening') {
      _onEnd?.call();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (kDebugMode) debugPrint('[BridgeLive Native] error: ${error.errorMsg}');
    if (error.permanent) {
      _onError?.call('permanent:${error.errorMsg}');
    } else {
      _onError?.call(error.errorMsg);
    }
  }

  Future<void> listen({String lang = 'ko-KR'}) async {
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _onResult?.call(result.recognizedWords);
        } else {
          _onPartial?.call(result.recognizedWords);
        }
      },
      listenFor: _listenFor,
      pauseFor: _pauseFor,
      localeId: lang,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }
}
