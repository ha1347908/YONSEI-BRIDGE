// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

import 'bridge_live_web.dart'
    if (dart.library.io) 'bridge_live_stub.dart' as speech_impl;

class BridgeLiveScreen extends StatefulWidget {
  const BridgeLiveScreen({super.key});

  @override
  State<BridgeLiveScreen> createState() => _BridgeLiveScreenState();
}

class _BridgeLiveScreenState extends State<BridgeLiveScreen>
    with WidgetsBindingObserver {

  // ── 상태 변수 ───────────────────────────────────────────────
  bool _isListening = false;       // 마이크 ON/OFF (버튼 상태)
  bool _isInitializing = true;
  bool _speechAvailable = false;
  String _initError = '';

  // 텍스트 버퍼
  String _displayText = '';        // 화면에 표시되는 한국어 (final 누적 + 현재 interim)
  String _finalBuffer = '';        // 확정된 텍스트만 누적
  String _interimBuffer = '';      // 현재 인식 중인 interim

  // 번역
  String _translatedText = '';
  bool _isTranslating = false;

  // 번역 디바운스
  Timer? _translateTimer;
  String _lastTranslated = '';

  // 재시작 제어 — 이 플래그 하나로만 결정
  bool _shouldKeepListening = false;

  speech_impl.SpeechController? _webController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSpeech());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _translateTimer?.cancel();
    _shouldKeepListening = false;
    _webController?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _shouldKeepListening = false;
      _webController?.stop();
      if (mounted) setState(() { _isListening = false; });
    }
  }

  // ── 초기화 ──────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    if (!mounted) return;
    setState(() { _isInitializing = true; _initError = ''; _speechAvailable = false; });
    try {
      _webController = speech_impl.SpeechController();
      final ok = await _webController!.initialize(
        onResult:  _onResult,
        onPartial: _onPartial,
        onError:   _onError,
        onEnd:     _onEnd,
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = ok;
        _isInitializing = false;
        _initError = ok ? '' : '이 브라우저는 음성 인식을 지원하지 않습니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _speechAvailable = false; _isInitializing = false; _initError = e.toString(); });
    }
  }

  // ── Web Speech 콜백 ─────────────────────────────────────────

  /// interim 결과: 버퍼 업데이트 → UI 즉시 반영 → 디바운스 번역
  void _onPartial(String text) {
    if (!mounted) return;
    _interimBuffer = text;
    // 화면에 표시할 텍스트 = 확정 + 현재 인식 중
    final display = _finalBuffer.isEmpty ? text : '$_finalBuffer $text';
    setState(() => _displayText = display);

    // 300ms 디바운스 번역
    _translateTimer?.cancel();
    if (text.trim().length < 2) return;
    _translateTimer = Timer(const Duration(milliseconds: 300), () {
      final src = display.trim();
      if (src != _lastTranslated && src.isNotEmpty) {
        _lastTranslated = src;
        _doTranslate(src);
      }
    });
  }

  /// final 결과: 확정 버퍼에 추가 → interim 클리어 → 즉시 번역
  void _onResult(String text) {
    if (!mounted || text.trim().isEmpty) return;
    _translateTimer?.cancel();
    _interimBuffer = '';
    _finalBuffer = _finalBuffer.isEmpty ? text : '$_finalBuffer $text';
    setState(() => _displayText = _finalBuffer);

    if (_finalBuffer != _lastTranslated) {
      _lastTranslated = _finalBuffer;
      _doTranslate(_finalBuffer);
    }
  }

  /// 에러: 재시작만 판단, UI는 건드리지 않음
  void _onError(String error) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('[BridgeLive] error: $error');
    // no-speech는 조용히 재시작 (UI 변경 없음)
    if (_shouldKeepListening) {
      final isRecoverable = error.contains('no-speech') ||
          error.contains('network') ||
          error.contains('aborted');
      if (isRecoverable) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_shouldKeepListening && mounted) _webController?.listen(lang: 'ko-KR');
        });
      } else {
        // 심각한 에러면 버튼 상태만 업데이트
        if (mounted) setState(() => _isListening = false);
      }
    }
  }

  /// onend: 재시작만 처리, setState 최소화
  void _onEnd() {
    if (!mounted) return;
    if (_shouldKeepListening) {
      // UI 변경 없이 바로 재시작
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_shouldKeepListening && mounted) {
          _webController?.listen(lang: 'ko-KR');
        }
      });
    } else {
      setState(() => _isListening = false);
    }
  }

  // ── 시작 / 정지 ──────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechAvailable || _isListening) return;
    _shouldKeepListening = true;
    setState(() => _isListening = true);
    await _webController?.listen(lang: 'ko-KR');
  }

  Future<void> _stopListening() async {
    _shouldKeepListening = false;
    _translateTimer?.cancel();
    await _webController?.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _interimBuffer = '';
        // _displayText는 유지 (마지막 인식 결과 보존)
      });
    }
  }

  // ── 번역 ─────────────────────────────────────────────────────
  Future<void> _doTranslate(String text) async {
    if (!mounted || text.trim().isEmpty) return;
    final lang = Provider.of<LanguageService>(context, listen: false);
    final target = lang.currentLanguage;

    if (target == 'ko') {
      if (mounted) setState(() => _translatedText = text);
      return;
    }

    if (mounted) setState(() => _isTranslating = true);
    try {
      final result = await TranslationService.translate(
        text: text, targetLang: target, sourceLang: 'ko',
      );
      if (mounted) setState(() { _translatedText = result; _isTranslating = false; });
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _clearAll() {
    _translateTimer?.cancel();
    _lastTranslated = '';
    _finalBuffer = '';
    _interimBuffer = '';
    setState(() { _displayText = ''; _translatedText = ''; });
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(children: [
          Icon(Icons.radio_button_checked, color: Color(0xFF4ECDC4), size: 16),
          SizedBox(width: 8),
          Text('Bridge Live',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                  color: Colors.white, letterSpacing: 0.5)),
        ]),
        actions: [
          if (_displayText.isNotEmpty || _translatedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _isInitializing
            ? _buildLoading()
            : !_speechAvailable
                ? _buildUnavailable()
                : _buildMain(lang),
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      SizedBox(height: 20),
      Text('마이크 초기화 중...', style: TextStyle(color: Colors.white70, fontSize: 15)),
      SizedBox(height: 8),
      Text('브라우저 마이크 권한 요청이 나타날 수 있습니다',
          style: TextStyle(color: Colors.white38, fontSize: 12)),
    ]),
  );

  Widget _buildUnavailable() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.hearing_disabled, size: 72, color: Colors.orange),
        const SizedBox(height: 24),
        const Text('음성 인식 초기화 실패',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('브라우저의 마이크 권한을 허용하거나\n다시 시도해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6)),
        if (_initError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_initError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ],
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _initSpeech,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildMain(LanguageService lang) {
    final isKorean = lang.currentLanguage == 'ko';
    final langName = _getLangName(lang.currentLanguage);
    final hasContent = _displayText.isNotEmpty || _translatedText.isNotEmpty;

    return Column(children: [
      // 안내 배너
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white.withValues(alpha: 0.04),
        child: Row(children: [
          const Icon(Icons.translate, color: Color(0xFF4ECDC4), size: 16),
          const SizedBox(width: 8),
          Text(
            isKorean ? '말하면 바로 글자로 표시됩니다' : '한국어 인식 → $langName 실시간 번역',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ]),
      ),

      // 결과 영역
      Expanded(
        child: !hasContent
            ? _buildGuide()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ① 번역 결과 (최상단, 크게)
                  if (!isKorean && (_translatedText.isNotEmpty || _isTranslating))
                    _buildTranslatedCard(langName),

                  if (!isKorean && (_translatedText.isNotEmpty || _isTranslating))
                    const SizedBox(height: 16),

                  // ② 한국어 인식 텍스트 (final + interim 합산)
                  if (_displayText.isNotEmpty)
                    _buildKoreanCard(),
                ]),
              ),
      ),

      _buildControlBar(),
    ]);
  }

  // 번역 결과 카드
  Widget _buildTranslatedCard(String langName) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF161B38),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.5), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.translate, size: 13, color: Color(0xFFFFD93D)),
        const SizedBox(width: 6),
        Text(langName,
            style: const TextStyle(fontSize: 11, color: Color(0xFFFFD93D),
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        if (_isTranslating) ...[
          const SizedBox(width: 10),
          const SizedBox(width: 10, height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFFD93D))),
        ],
      ]),
      const SizedBox(height: 14),
      Text(
        _translatedText.isNotEmpty ? _translatedText : '번역 중...',
        style: TextStyle(
          fontSize: 22,
          color: _translatedText.isNotEmpty ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    ]),
  );

  // 한국어 인식 카드 (interim 포함 실시간)
  Widget _buildKoreanCard() {
    final isLive = _isListening && _interimBuffer.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isLive) ...[_LiveDot(), const SizedBox(width: 6)],
          if (!isLive)
            const Icon(Icons.record_voice_over, size: 13, color: Colors.white38),
          if (!isLive) const SizedBox(width: 6),
          Text(
            isLive ? '인식 중...' : '인식된 한국어',
            style: TextStyle(
                fontSize: 11,
                color: isLive ? const Color(0xFF4ECDC4) : Colors.white38,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
        ]),
        const SizedBox(height: 10),
        // ★ final + interim 합산 텍스트 표시
        RichText(
          text: TextSpan(
            children: [
              if (_finalBuffer.isNotEmpty)
                TextSpan(
                  text: _finalBuffer,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white, height: 1.6),
                ),
              if (_finalBuffer.isNotEmpty && _interimBuffer.isNotEmpty)
                const TextSpan(text: ' '),
              if (_interimBuffer.isNotEmpty)
                TextSpan(
                  text: _interimBuffer,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.6),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildGuide() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.mic, size: 44, color: Color(0xFF4ECDC4)),
      ),
      const SizedBox(height: 24),
      const Text('아래 버튼을 눌러 시작하세요',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      const Text('한국어로 말하면 즉시 번역됩니다',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
    ]),
  );

  Widget _buildControlBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1130),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        _isListening ? '듣고 있어요 — 한국어로 말씀해 주세요' : '마이크 버튼을 눌러 시작',
        style: TextStyle(
          color: _isListening ? const Color(0xFF4ECDC4) : Colors.white30,
          fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _isListening ? _stopListening : _startListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isListening
                ? const Color(0xFF4ECDC4)
                : const Color(0xFF4ECDC4).withValues(alpha: 0.12),
            border: Border.all(color: const Color(0xFF4ECDC4), width: 2),
            boxShadow: _isListening
                ? [BoxShadow(color: const Color(0xFF4ECDC4).withValues(alpha: 0.35),
                    blurRadius: 18, spreadRadius: 3)]
                : null,
          ),
          child: Icon(
            _isListening ? Icons.stop_rounded : Icons.mic,
            size: 30,
            color: _isListening ? Colors.black87 : const Color(0xFF4ECDC4),
          ),
        ),
      ),
    ]),
  );

  String _getLangName(String code) {
    switch (code) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      default:   return code;
    }
  }
}

// ── 깜박이는 점 ───────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ECDC4)),
    ),
  );
}
