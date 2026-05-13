// 네이티브(Android/iOS) 전용: speech_to_text 패키지 사용
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechController {
  final stt.SpeechToText _speech = stt.SpeechToText();

  void Function(String)? onResult;
  void Function(String)? onPartial;
  void Function(String)? onError;
  void Function()? onEnd;

  Future<bool> initialize() async {
    final permStatus = await Permission.microphone.status;
    if (permStatus.isPermanentlyDenied) return false;
    try {
      final ok = await _speech.initialize(
        onStatus: (s) {
          if (kDebugMode) debugPrint('[STT-Native] status: $s');
          if (s == 'done' || s == 'notListening') onEnd?.call();
        },
        onError: (e) {
          if (kDebugMode) debugPrint('[STT-Native] error: ${e.errorMsg}');
          onError?.call(e.errorMsg);
        },
        debugLogging: kDebugMode,
      );
      if (!ok) {
        await Future.delayed(const Duration(milliseconds: 800));
        return await _speech.initialize();
      }
      return ok;
    } catch (e) {
      return false;
    }
  }

  void startSession({String lang = 'ko-KR'}) {
    _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (r.finalResult) {
          onResult?.call(r.recognizedWords);
        } else {
          onPartial?.call(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: lang,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  void abort() {
    try { _speech.stop(); } catch (_) {}
  }
}
