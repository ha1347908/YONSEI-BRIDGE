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

  // ─── 상태 ───────────────────────────────────────────────────
  bool _ready = false;        // 초기화 완료
  bool _initError = false;
  String _initErrMsg = '';

  // 마이크 ON/OFF - Screen이 직접 소유
  bool _active = false;       // true = 녹음 중 (버튼 = 정지)
  bool _wantListen = false;   // 사용자 의도 플래그

  // 텍스트
  String _finalBuf = '';      // 확정된 한국어 누적
  String _interimBuf = '';    // 현재 인식 중 (미확정)
  String _translated = '';    // 번역 결과
  bool _translating = false;

  // 번역 디바운스
  Timer? _debounce;
  String _lastSrc = '';

  late speech_impl.SpeechController _ctrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _wantListen = false;
    _ctrl.abort();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.detached) {
      _wantListen = false;
      _ctrl.abort();
      if (mounted) setState(() => _active = false);
    }
  }

  // ─── 초기화 ─────────────────────────────────────────────────
  Future<void> _init() async {
    if (!mounted) return;
    setState(() { _ready = false; _initError = false; _initErrMsg = ''; });
    try {
      _ctrl = speech_impl.SpeechController();

      // 콜백 등록
      _ctrl.onResult  = _onResult;
      _ctrl.onPartial = _onPartial;
      _ctrl.onError   = _onError;
      _ctrl.onEnd     = _onEnd;

      final ok = await _ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _ready = ok;
        _initError = !ok;
        _initErrMsg = ok ? '' : '이 브라우저는 음성 인식을 지원하지 않습니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _ready = false; _initError = true; _initErrMsg = e.toString(); });
    }
  }

  // ─── 콜백 ───────────────────────────────────────────────────

  void _onPartial(String text) {
    if (!mounted || !_active) return;
    setState(() => _interimBuf = text);

    // 디바운스 번역 (300ms)
    _debounce?.cancel();
    final full = _combined(text);
    if (full.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (full != _lastSrc) { _lastSrc = full; _translate(full); }
    });
  }

  void _onResult(String text) {
    if (!mounted || text.trim().isEmpty) return;
    _debounce?.cancel();
    _finalBuf = _finalBuf.isEmpty ? text : '$_finalBuf $text';
    _interimBuf = '';
    setState(() {}); // _finalBuf, _interimBuf 업데이트

    if (_finalBuf != _lastSrc) { _lastSrc = _finalBuf; _translate(_finalBuf); }
  }

  /// 에러: no-speech 는 재시작, 나머지는 중단
  void _onError(String err) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('[BridgeLive] err: $err');
    if (!_wantListen) return;

    if (err.contains('no-speech') || err.contains('aborted') || err.contains('network')) {
      // 조용히 재시작 — UI 변경 없음
      Future.delayed(const Duration(milliseconds: 300), _tryStartSession);
    } else {
      // 심각한 에러: 멈춤
      setState(() { _active = false; _wantListen = false; });
    }
  }

  /// 세션 종료: 사용자가 원하면 즉시 재시작
  void _onEnd() {
    if (!mounted) return;
    if (_wantListen) {
      // UI 변경 없이 재시작
      Future.delayed(const Duration(milliseconds: 150), _tryStartSession);
    } else {
      setState(() => _active = false);
    }
  }

  // ─── 세션 제어 ───────────────────────────────────────────────

  void _tryStartSession() {
    if (!mounted || !_wantListen) return;
    _ctrl.abort();                    // 혹시 남은 인스턴스 정리
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !_wantListen) return;
      _ctrl.startSession(lang: 'ko-KR');
    });
  }

  void _startListening() {
    if (!_ready || _active) return;
    _wantListen = true;
    setState(() { _active = true; _interimBuf = ''; });
    _ctrl.startSession(lang: 'ko-KR');
  }

  void _stopListening() {
    _wantListen = false;
    _debounce?.cancel();
    _ctrl.abort();
    if (mounted) setState(() { _active = false; _interimBuf = ''; });
  }

  // ─── 번역 ────────────────────────────────────────────────────
  Future<void> _translate(String src) async {
    if (!mounted || src.trim().isEmpty) return;
    final lang = Provider.of<LanguageService>(context, listen: false);
    if (lang.currentLanguage == 'ko') {
      setState(() => _translated = src);
      return;
    }
    setState(() => _translating = true);
    try {
      final r = await TranslationService.translate(
        text: src, targetLang: lang.currentLanguage, sourceLang: 'ko',
      );
      if (mounted) setState(() { _translated = r; _translating = false; });
    } catch (_) {
      if (mounted) setState(() => _translating = false);
    }
  }

  String _combined(String interim) =>
      _finalBuf.isEmpty ? interim : '$_finalBuf $interim';

  void _clear() {
    _debounce?.cancel();
    _lastSrc = '';
    _finalBuf = '';
    _interimBuf = '';
    setState(() => _translated = '');
  }

  // ─── UI ─────────────────────────────────────────────────────
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
          Icon(Icons.radio_button_checked, color: Color(0xFF4ECDC4), size: 15),
          SizedBox(width: 8),
          Text('Bridge Live',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                  color: Colors.white, letterSpacing: 0.5)),
        ]),
        actions: [
          if (_finalBuf.isNotEmpty || _translated.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: !_ready
            ? _buildNotReady()
            : _buildMain(lang),
      ),
    );
  }

  Widget _buildNotReady() {
    if (_initError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.hearing_disabled, size: 64, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('음성 인식 초기화 실패',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_initErrMsg, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ]),
        ),
      );
    }
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: Color(0xFF4ECDC4)),
        SizedBox(height: 16),
        Text('마이크 초기화 중...', style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _buildMain(LanguageService lang) {
    final isKo = lang.currentLanguage == 'ko';
    final langName = _langName(lang.currentLanguage);
    final hasContent = _finalBuf.isNotEmpty || _translated.isNotEmpty || _interimBuf.isNotEmpty;

    return Column(children: [
      // 상단 배너
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        color: Colors.white.withValues(alpha: 0.04),
        child: Row(children: [
          const Icon(Icons.translate, color: Color(0xFF4ECDC4), size: 15),
          const SizedBox(width: 8),
          Text(
            isKo ? '말하면 바로 글자로 표시됩니다' : '한국어 → $langName 실시간 번역',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ]),
      ),

      // 콘텐츠
      Expanded(
        child: hasContent
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ① 번역 결과 (상단, 크게)
                  if (!isKo)
                    _TranslatedCard(
                      text: _translated,
                      langName: langName,
                      loading: _translating,
                    ),
                  if (!isKo) const SizedBox(height: 16),

                  // ② 한국어 (final=흰색 + interim=회색)
                  if (_finalBuf.isNotEmpty || _interimBuf.isNotEmpty)
                    _KoreanCard(
                      finalText: _finalBuf,
                      interimText: _interimBuf,
                      active: _active,
                    ),
                ]),
              )
            : _buildGuide(),
      ),

      _buildBar(),
    ]);
  }

  Widget _buildGuide() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 92, height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.mic, size: 42, color: Color(0xFF4ECDC4)),
      ),
      const SizedBox(height: 22),
      const Text('아래 버튼을 눌러 시작하세요',
          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      const Text('한국어로 말하면 즉시 번역됩니다',
          style: TextStyle(color: Colors.white38, fontSize: 12)),
    ]),
  );

  Widget _buildBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
    decoration: BoxDecoration(
      color: const Color(0xFF0C1030),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        _active ? '듣고 있어요 — 한국어로 말씀해 주세요' : '마이크 버튼을 눌러 시작',
        style: TextStyle(
          color: _active ? const Color(0xFF4ECDC4) : Colors.white30,
          fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: _active ? _stopListening : _startListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68, height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _active
                ? const Color(0xFF4ECDC4)
                : const Color(0xFF4ECDC4).withValues(alpha: 0.12),
            border: Border.all(color: const Color(0xFF4ECDC4), width: 2),
            boxShadow: _active
                ? [BoxShadow(color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                    blurRadius: 16, spreadRadius: 2)]
                : null,
          ),
          child: Icon(
            _active ? Icons.stop_rounded : Icons.mic,
            size: 28,
            color: _active ? Colors.black87 : const Color(0xFF4ECDC4),
          ),
        ),
      ),
    ]),
  );

  String _langName(String c) {
    switch (c) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      default:   return c;
    }
  }
}

// ─── 번역 결과 카드 ───────────────────────────────────────────
class _TranslatedCard extends StatelessWidget {
  final String text;
  final String langName;
  final bool loading;
  const _TranslatedCard({required this.text, required this.langName, required this.loading});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF161B38),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.45), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.translate, size: 12, color: Color(0xFFFFD93D)),
        const SizedBox(width: 6),
        Text(langName,
            style: const TextStyle(fontSize: 11, color: Color(0xFFFFD93D),
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        if (loading) ...[
          const SizedBox(width: 8),
          const SizedBox(width: 10, height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFFD93D))),
        ],
      ]),
      const SizedBox(height: 12),
      Text(
        text.isNotEmpty ? text : '번역 중...',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: text.isNotEmpty ? Colors.white : Colors.white30,
          height: 1.5,
        ),
      ),
    ]),
  );
}

// ─── 한국어 인식 카드 ─────────────────────────────────────────
class _KoreanCard extends StatelessWidget {
  final String finalText;
  final String interimText;
  final bool active;
  const _KoreanCard({required this.finalText, required this.interimText, required this.active});

  @override
  Widget build(BuildContext context) {
    final isLive = active && interimText.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (isLive) ...[
            _Dot(), const SizedBox(width: 6),
            const Text('인식 중...',
                style: TextStyle(fontSize: 11, color: Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w600)),
          ] else ...[
            const Icon(Icons.record_voice_over, size: 12, color: Colors.white38),
            const SizedBox(width: 6),
            const Text('인식된 한국어',
                style: TextStyle(fontSize: 11, color: Colors.white38,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(children: [
            if (finalText.isNotEmpty)
              TextSpan(text: finalText,
                  style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.6)),
            if (finalText.isNotEmpty && interimText.isNotEmpty)
              const TextSpan(text: ' '),
            if (interimText.isNotEmpty)
              TextSpan(text: interimText,
                  style: TextStyle(fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.5), height: 1.6)),
          ]),
        ),
      ]),
    );
  }
}

// ─── 깜박이는 점 ──────────────────────────────────────────────
class _Dot extends StatefulWidget {
  @override
  State<_Dot> createState() => _DotState();
}
class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(_c);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 7, height: 7,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ECDC4))),
  );
}
