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

  bool _ready = false;
  bool _initError = false;
  String _initErrMsg = '';

  bool _active = false;
  bool _wantListen = false;

  String _finalBuf = '';
  String _interimBuf = '';
  String _translated = '';
  bool _translating = false;

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

  Future<void> _init() async {
    if (!mounted) return;
    setState(() { _ready = false; _initError = false; _initErrMsg = ''; });
    try {
      _ctrl = speech_impl.SpeechController();
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
    _debounce?.cancel();
    final full = _finalBuf.isEmpty ? text : '$_finalBuf $text';
    if (full.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (full != _lastSrc) { _lastSrc = full; _translate(full); }
    });
  }

  void _onResult(String text) {
    if (!mounted || text.trim().isEmpty) return;
    _debounce?.cancel();
    _finalBuf = _finalBuf.isEmpty ? text : '$_finalBuf $text';
    _interimBuf = '';
    setState(() {});
    if (_finalBuf != _lastSrc) { _lastSrc = _finalBuf; _translate(_finalBuf); }
  }

  void _onError(String err) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('[BridgeLive] err: $err');
    if (!_wantListen) return;
    if (err.contains('no-speech') || err.contains('aborted') || err.contains('network')) {
      Future.delayed(const Duration(milliseconds: 300), _tryStart);
    } else {
      setState(() { _active = false; _wantListen = false; });
    }
  }

  void _onEnd() {
    if (!mounted) return;
    if (_wantListen) {
      Future.delayed(const Duration(milliseconds: 150), _tryStart);
    } else {
      setState(() => _active = false);
    }
  }

  void _tryStart() {
    if (!mounted || !_wantListen) return;
    _ctrl.abort();
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
        child: !_ready ? _buildNotReady() : _buildMain(lang),
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

    return Column(
      children: [
        // ── 결과 영역 (항상 표시) ──────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(children: [

              // ① 번역 결과 박스 (한국어 설정이 아닐 때만)
              if (!isKo)
                Expanded(
                  flex: 3,
                  child: _AlwaysBox(
                    label: langName,
                    labelIcon: Icons.translate,
                    labelColor: const Color(0xFFFFD93D),
                    borderColor: const Color(0xFFFFD93D),
                    bgColor: const Color(0xFF161B38),
                    placeholder: _active ? '번역 대기 중...' : '마이크를 켜고 한국어로 말씀해 주세요',
                    text: _translated,
                    textSize: 22,
                    textWeight: FontWeight.w600,
                    loading: _translating,
                    active: _active,
                  ),
                ),

              if (!isKo) const SizedBox(height: 12),

              // ② 한국어 인식 박스 (항상 표시)
              Expanded(
                flex: 2,
                child: _AlwaysBox(
                  label: '한국어 인식',
                  labelIcon: Icons.mic,
                  labelColor: const Color(0xFF4ECDC4),
                  borderColor: _active ? const Color(0xFF4ECDC4) : Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.04),
                  placeholder: _active ? '듣고 있어요...' : '마이크를 켜면 여기에 말한 내용이 표시됩니다',
                  text: _finalBuf,
                  interimText: _interimBuf,
                  textSize: 17,
                  textWeight: FontWeight.normal,
                  active: _active,
                ),
              ),

            ]),
          ),
        ),

        // ── 컨트롤 바 ─────────────────────────────────────────
        _buildBar(),
      ],
    );
  }

  Widget _buildBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
    decoration: BoxDecoration(
      color: const Color(0xFF0C1030),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 상태 텍스트
        Expanded(
          child: Text(
            _active ? '듣고 있어요 — 한국어로 말씀해 주세요' : '마이크 버튼을 눌러 시작',
            style: TextStyle(
              color: _active ? const Color(0xFF4ECDC4) : Colors.white30,
              fontSize: 13, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // 마이크 버튼
        GestureDetector(
          onTap: _active ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64, height: 64,
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
      ],
    ),
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

// ─── 항상 표시되는 텍스트 박스 ───────────────────────────────────
class _AlwaysBox extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final Color labelColor;
  final Color borderColor;
  final Color bgColor;
  final String placeholder;
  final String text;
  final String interimText;
  final double textSize;
  final FontWeight textWeight;
  final bool loading;
  final bool active;

  const _AlwaysBox({
    required this.label,
    required this.labelIcon,
    required this.labelColor,
    required this.borderColor,
    required this.bgColor,
    required this.placeholder,
    required this.text,
    this.interimText = '',
    required this.textSize,
    required this.textWeight,
    this.loading = false,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = text.isNotEmpty || interimText.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (active ? borderColor : Colors.white).withValues(alpha: active ? 0.5 : 0.12),
          width: active ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨 행
          Row(children: [
            Icon(labelIcon, size: 12, color: labelColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 11, color: labelColor,
                    fontWeight: FontWeight.w700, letterSpacing: 0.7)),
            if (loading) ...[
              const SizedBox(width: 8),
              SizedBox(width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: labelColor)),
            ],
            if (active && !hasText && !loading) ...[
              const SizedBox(width: 8),
              _Pulse(color: labelColor),
            ],
          ]),
          const SizedBox(height: 12),

          // 텍스트 영역
          Expanded(
            child: SingleChildScrollView(
              child: hasText
                  ? RichText(
                      text: TextSpan(children: [
                        if (text.isNotEmpty)
                          TextSpan(text: text,
                              style: TextStyle(fontSize: textSize, fontWeight: textWeight,
                                  color: Colors.white, height: 1.5)),
                        if (text.isNotEmpty && interimText.isNotEmpty)
                          const TextSpan(text: ' '),
                        if (interimText.isNotEmpty)
                          TextSpan(text: interimText,
                              style: TextStyle(fontSize: textSize, fontWeight: textWeight,
                                  color: Colors.white.withValues(alpha: 0.45), height: 1.5)),
                      ]),
                    )
                  : Text(placeholder,
                      style: TextStyle(
                        fontSize: textSize * 0.75,
                        color: Colors.white.withValues(alpha: active ? 0.35 : 0.2),
                        height: 1.5,
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 박동 애니메이션 점 (녹음 중 표시용) ─────────────────────────
class _Pulse extends StatefulWidget {
  final Color color;
  const _Pulse({required this.color});
  @override
  State<_Pulse> createState() => _PulseState();
}
class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 6, height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
  );
}
