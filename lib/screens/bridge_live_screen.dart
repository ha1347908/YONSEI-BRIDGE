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
//   - 웹(Safari/Chrome): Web Speech API (webkitSpeechRecognition)
//   - 안드로이드/iOS 앱: speech_to_text 패키지
//   - 한국어 인식 → 사용자 언어 실시간 번역
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

  String _recognizedText = '';
  String _translatedText = '';
  String _currentWords = '';

  bool _shouldKeepListening = false;

  // Web Speech API controller (웹 전용)
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
  void _onPartial(String text) {
    if (!mounted) return;
    setState(() => _currentWords = text);
  }

  void _onResult(String text) {
    if (!mounted || text.trim().isEmpty) return;
    setState(() {
      _recognizedText = text;
      _currentWords = '';
    });
    _translateText(text);
  }

  void _onError(String error) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('BridgeLive error: $error');
    setState(() => _isListening = false);
    // no-speech 나 network 에러는 재시작
    if (_shouldKeepListening &&
        (error.contains('no-speech') || error.contains('network') || error.contains('aborted'))) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_shouldKeepListening && mounted) _doListen();
      });
    }
  }

  void _onEnd() {
    if (!mounted) return;
    setState(() => _isListening = false);
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
      _currentWords = '';
    });
    await _webController?.listen(lang: 'ko-KR');
  }

  Future<void> _stopListening() async {
    _shouldKeepListening = false;
    await _webController?.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentWords = '';
      });
    }
  }

  // ── 번역 ────────────────────────────────────────────────────
  Future<void> _translateText(String text) async {
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
      if (mounted) setState(() { _translatedText = text; _isTranslating = false; });
    }
  }

  void _clearResults() {
    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _currentWords = '';
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
          if (_recognizedText.isNotEmpty || _translatedText.isNotEmpty)
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
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
              style:
                  TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
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
    return Column(children: [
      // 배너
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border:
              Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
      // 결과
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_isListening && _currentWords.isNotEmpty)
              _buildCard(label: '인식 중...', text: _currentWords, isLive: true, labelColor: const Color(0xFF4ECDC4)),
            if (_recognizedText.isNotEmpty) ...[
              _buildCard(label: '인식된 한국어', text: _recognizedText, icon: Icons.record_voice_over, labelColor: Colors.white70),
              const SizedBox(height: 16),
            ],
            if (_isTranslating)
              _buildCard(label: '번역 중...', text: '...', isLive: true, labelColor: const Color(0xFFFFD93D))
            else if (_translatedText.isNotEmpty && !isKorean)
              _buildCard(label: targetLangName, text: _translatedText, icon: Icons.translate, labelColor: const Color(0xFFFFD93D), isHighlighted: true),
            if (_recognizedText.isEmpty && _translatedText.isEmpty && (!_isListening || _currentWords.isEmpty))
              _buildGuide(),
          ]),
        ),
      ),
      _buildControlBar(),
    ]);
  }

  Widget _buildGuide() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.mic, size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 24),
            const Text('아래 버튼을 눌러 시작하세요',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
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
    bool isHighlighted = false,
    IconData? icon,
    Color labelColor = Colors.white70,
  }) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF1A1F40) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFFFD93D).withValues(alpha: 0.4)
                : isLive
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
            width: isHighlighted || isLive ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 14, color: labelColor), const SizedBox(width: 6)]
            else if (isLive) ...[_LiveDot(), const SizedBox(width: 6)],
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: labelColor, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          Text(text,
              style: TextStyle(
                  fontSize: isHighlighted ? 20 : 16,
                  color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                  height: 1.5)),
        ]),
      );

  Widget _buildControlBar() => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _isListening ? '음성 인식 중... 말씀해주세요' : _shouldKeepListening ? '재시작 중...' : '마이크 버튼을 눌러 시작',
            style: TextStyle(
                color: _isListening ? const Color(0xFF4ECDC4) : Colors.white38,
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? const Color(0xFF4ECDC4) : const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF4ECDC4), width: 2),
                boxShadow: _isListening
                    ? [BoxShadow(color: const Color(0xFF4ECDC4).withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)]
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
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      default: return code;
    }
  }
}

// ── 깜박이는 라이브 점 ──────────────────────────────────────────
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
