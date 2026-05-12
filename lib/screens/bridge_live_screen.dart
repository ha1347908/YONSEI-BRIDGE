// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

// 웹 전용 import (조건부)
import 'bridge_live_web.dart'
    if (dart.library.io) 'bridge_live_stub.dart' as speech_impl;

// ──────────────────────────────────────────────────────────────
// Bridge Live 화면
//   - 웹(Safari/Chrome): Web Speech API (continuous=true, interimResults=true)
//   - 안드로이드/iOS 앱: speech_to_text 패키지
//   - 한국어 인식 → 사용자 언어 실시간 번역 (partial 즉시 번역)
// ──────────────────────────────────────────────────────────────
class BridgeLiveScreen extends StatefulWidget {
  const BridgeLiveScreen({super.key});

  @override
  State<BridgeLiveScreen> createState() => _BridgeLiveScreenState();
}

class _BridgeLiveScreenState extends State<BridgeLiveScreen>
    with WidgetsBindingObserver {
  bool _isListening = false;
  bool _isTranslating = false;
  bool _isInitializing = true;
  bool _speechAvailable = false;
  String _initError = '';

  // 인식된 텍스트 (최종 누적)
  String _finalText = '';
  // 현재 인식 중인 중간 텍스트
  String _interimText = '';
  // 번역된 텍스트 (실시간 업데이트)
  String _translatedText = '';

  bool _shouldKeepListening = false;

  // 번역 디바운스 타이머 (연속 partial에서 중복 API 호출 방지)
  Timer? _translateTimer;
  String _lastTranslatedSource = ''; // 마지막으로 번역한 원문 (중복 방지)

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
      if (mounted) setState(() => _isListening = false);
    }
  }

  // ── 초기화 ──────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _initError = '';
      _speechAvailable = false;
    });
    try {
      _webController = speech_impl.SpeechController();
      final available = await _webController!.initialize(
        onResult: _onResult,
        onPartial: _onPartial,
        onError: _onError,
        onEnd: _onEnd,
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
        _isInitializing = false;
        _initError = available ? '' : '음성 인식을 지원하지 않는 브라우저입니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  // ── 결과 콜백 ────────────────────────────────────────────────

  /// 중간(interim) 인식 결과 → 화면에 즉시 표시 + 디바운스 번역
  void _onPartial(String text) {
    if (!mounted) return;
    setState(() => _interimText = text);

    // 디바운스: 300ms 내 새 partial이 오면 이전 번역 취소
    _translateTimer?.cancel();
    if (text.trim().length < 2) return; // 너무 짧으면 번역 스킵
    _translateTimer = Timer(const Duration(milliseconds: 300), () {
      final combined = (_finalText + ' ' + text).trim();
      if (combined != _lastTranslatedSource) {
        _lastTranslatedSource = combined;
        _translateText(combined, isPartial: true);
      }
    });
  }

  /// 최종(final) 인식 결과 → 누적 저장 + 즉시 번역
  void _onResult(String text) {
    if (!mounted || text.trim().isEmpty) return;
    _translateTimer?.cancel();
    final newFinal = (_finalText.isEmpty ? '' : '$_finalText ') + text;
    setState(() {
      _finalText = newFinal;
      _interimText = '';
    });
    // 최종 확정 텍스트로 즉시 번역 (중복 방지)
    if (newFinal != _lastTranslatedSource) {
      _lastTranslatedSource = newFinal;
      _translateText(newFinal, isPartial: false);
    }
  }

  void _onError(String error) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('BridgeLive error: $error');
    setState(() => _isListening = false);
    if (_shouldKeepListening &&
        (error.contains('no-speech') ||
            error.contains('network') ||
            error.contains('aborted'))) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_shouldKeepListening && mounted) _doListen();
      });
    }
  }

  void _onEnd() {
    if (!mounted) return;
    setState(() => _isListening = false);
    // continuous=true에서 onend는 에러 후에만 오므로 바로 재시작
    if (_shouldKeepListening) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_shouldKeepListening && mounted) _doListen();
      });
    }
  }

  // ── 청취 시작/정지 ───────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    _shouldKeepListening = true;
    await _doListen();
  }

  Future<void> _doListen() async {
    if (!mounted || !_shouldKeepListening) return;
    setState(() {
      _isListening = true;
      _interimText = '';
    });
    await _webController?.listen(lang: 'ko-KR');
  }

  Future<void> _stopListening() async {
    _translateTimer?.cancel();
    _shouldKeepListening = false;
    await _webController?.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _interimText = '';
      });
    }
  }

  // ── 번역 ────────────────────────────────────────────────────
  Future<void> _translateText(String text, {bool isPartial = false}) async {
    if (!mounted || text.trim().isEmpty) return;
    final lang = Provider.of<LanguageService>(context, listen: false);
    final target = lang.currentLanguage;

    // 한국어 설정이면 번역 없이 바로 표시
    if (target == 'ko') {
      if (mounted) setState(() => _translatedText = text);
      return;
    }

    // partial은 _isTranslating 스피너 없이 조용히 번역 (UI 안 튀게)
    if (!isPartial && mounted) setState(() => _isTranslating = true);

    try {
      final result = await TranslationService.translate(
        text: text,
        targetLang: target,
        sourceLang: 'ko',
      );
      if (mounted) {
        setState(() {
          _translatedText = result;
          _isTranslating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _clearResults() {
    _translateTimer?.cancel();
    _lastTranslatedSource = '';
    setState(() {
      _finalText = '';
      _translatedText = '';
      _interimText = '';
    });
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.radio_button_checked, color: Color(0xFF4ECDC4), size: 16),
          SizedBox(width: 8),
          Text('Bridge Live',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 0.5)),
        ]),
        elevation: 0,
        actions: [
          if (_finalText.isNotEmpty || _translatedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: _clearResults,
            ),
        ],
      ),
      body: SafeArea(
        child: _isInitializing
            ? _buildInitView()
            : !_speechAvailable
                ? _buildUnavailableView()
                : _buildMainView(lang),
      ),
    );
  }

  Widget _buildInitView() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Color(0xFF4ECDC4)),
          SizedBox(height: 20),
          Text('마이크 초기화 중...',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          SizedBox(height: 8),
          Text('브라우저 마이크 권한 요청이 나타날 수 있습니다',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      );

  Widget _buildUnavailableView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.hearing_disabled, size: 72, color: Colors.orange),
            const SizedBox(height: 24),
            const Text('음성 인식 초기화 실패',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              '브라우저의 마이크 권한을 허용하거나\n다시 시도해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            ),
            if (_initError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_initError,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initSpeech,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ]),
        ),
      );

  Widget _buildMainView(LanguageService lang) {
    final targetLangName = _getLangName(lang.currentLanguage);
    final isKorean = lang.currentLanguage == 'ko';

    // 화면에 표시할 "현재 인식 중" 텍스트 (final + interim 합산)
    final displayInterim = _interimText;
    final hasContent = _finalText.isNotEmpty ||
        _translatedText.isNotEmpty ||
        displayInterim.isNotEmpty;

    return Column(children: [
      // 안내 배너
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(children: [
          const Icon(Icons.translate, color: Color(0xFF4ECDC4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isKorean
                  ? '한국어로 말하면 그대로 표시됩니다'
                  : '한국어 인식 → $targetLangName 실시간 번역',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ]),
      ),

      // 결과 영역
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ① 번역 결과 (가장 크게, 최상단)
            if (_translatedText.isNotEmpty && !isKorean) ...[
              _buildTranslationCard(
                label: targetLangName,
                text: _translatedText,
                isTranslating: _isTranslating,
              ),
              const SizedBox(height: 16),
            ],

            // ② 인식 중인 한국어 (실시간)
            if (_isListening && displayInterim.isNotEmpty) ...[
              _buildCard(
                label: '인식 중...',
                text: displayInterim,
                isLive: true,
                labelColor: const Color(0xFF4ECDC4),
              ),
              const SizedBox(height: 16),
            ],

            // ③ 최종 확정된 한국어 원문
            if (_finalText.isNotEmpty)
              _buildCard(
                label: '인식된 한국어',
                text: _finalText,
                icon: Icons.record_voice_over,
                labelColor: Colors.white54,
                dimmed: true,
              ),

            // 아무것도 없을 때 가이드
            if (!hasContent) _buildGuide(),
          ]),
        ),
      ),
      _buildControlBar(),
    ]);
  }

  Widget _buildTranslationCard({
    required String label,
    required String text,
    bool isTranslating = false,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD93D).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD93D).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.translate, size: 14, color: Color(0xFFFFD93D)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFD93D),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            if (isTranslating) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFFFFD93D),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.5)),
        ]),
      );

  Widget _buildGuide() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    width: 2),
              ),
              child:
                  const Icon(Icons.mic, size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 24),
            const Text('아래 버튼을 눌러 시작하세요',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('한국어로 말하면 자동으로 번역됩니다',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ]),
        ),
      );

  Widget _buildCard({
    required String label,
    required String text,
    bool isLive = false,
    bool dimmed = false,
    IconData? icon,
    Color labelColor = Colors.white70,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: dimmed ? 0.03 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: isLive ? 1.5 : 1,
          ),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: labelColor),
              const SizedBox(width: 6)
            ] else if (isLive) ...[
              _LiveDot(),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          Text(text,
              style: TextStyle(
                  fontSize: isLive ? 17 : 15,
                  color: dimmed
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.85),
                  height: 1.5)),
        ]),
      );

  Widget _buildControlBar() => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _isListening ? '듣고 있어요 — 한국어로 말씀해 주세요' : '마이크 버튼을 눌러 시작',
            style: TextStyle(
                color:
                    _isListening ? const Color(0xFF4ECDC4) : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? const Color(0xFF4ECDC4)
                    : const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                border:
                    Border.all(color: const Color(0xFF4ECDC4), width: 2),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                            color: const Color(0xFF4ECDC4)
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4)
                      ]
                    : null,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 32,
                color: _isListening ? Colors.black : const Color(0xFF4ECDC4),
              ),
            ),
          ),
        ]),
      );

  String _getLangName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return code;
    }
  }
}

// ── 깜박이는 라이브 점 ───────────────────────────────────────────
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
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF4ECDC4)),
        ),
      );
}
