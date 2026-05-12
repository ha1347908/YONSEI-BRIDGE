import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

// ──────────────────────────────────────────────────────────────
// Bridge Live 화면
//   - 한국어 음성 인식 (speech_to_text)
//   - 사용자 설정 언어로 실시간 번역 (TranslationService)
//   - 인식이 꺼지지 않고 지속적으로 작동
// ──────────────────────────────────────────────────────────────
class BridgeLiveScreen extends StatefulWidget {
  const BridgeLiveScreen({super.key});

  @override
  State<BridgeLiveScreen> createState() => _BridgeLiveScreenState();
}

class _BridgeLiveScreenState extends State<BridgeLiveScreen>
    with WidgetsBindingObserver {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isTranslating = false;
  bool _micPermissionDenied = false;
  bool _isInitializing = true;

  // 인식된 원문 (한국어)
  String _recognizedText = '';
  // 번역된 텍스트
  String _translatedText = '';
  // 현재 인식 중인 임시 텍스트
  String _currentWords = '';

  // 지속 청취 관련
  bool _shouldKeepListening = false;
  static const Duration _listenFor = Duration(seconds: 30);
  static const Duration _pauseFor = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shouldKeepListening = false;
    _speech.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _shouldKeepListening = false;
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  // ── 초기화 ────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);

    // 마이크 권한 확인 및 요청
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _micPermissionDenied = true;
        _isInitializing = false;
      });
      return;
    }

    // speech_to_text 초기화
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('BridgeLive: speech init error: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _isInitializing = false;
        });
      }
    }
  }

  // ── 음성 인식 시작 ────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechAvailable || _isListening) return;
    _shouldKeepListening = true;
    await _doListen();
  }

  Future<void> _doListen() async {
    if (!_shouldKeepListening || !mounted) return;
    setState(() {
      _isListening = true;
      _currentWords = '';
    });
    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: _listenFor,
      pauseFor: _pauseFor,
      localeId: 'ko_KR',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  // ── 음성 인식 정지 ────────────────────────────────────────────
  Future<void> _stopListening() async {
    _shouldKeepListening = false;
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentWords = '';
      });
    }
  }

  // ── 음성 인식 콜백 ────────────────────────────────────────────
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _currentWords = result.recognizedWords;
    });
    // 최종 결과가 나왔을 때 번역
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _recognizedText = result.recognizedWords;
      _translateText(result.recognizedWords);
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('BridgeLive status: $status');
    // 인식 완료/대기 상태가 되면 자동으로 재시작 (지속 청취)
    if ((status == 'done' || status == 'notListening') && _shouldKeepListening) {
      setState(() => _isListening = false);
      // 약간의 딜레이 후 재시작
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_shouldKeepListening && mounted) {
          _doListen();
        }
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    if (kDebugMode) debugPrint('BridgeLive error: ${error.errorMsg}');
    // 에러 후에도 지속 청취 중이면 재시작
    if (_shouldKeepListening) {
      setState(() => _isListening = false);
      Future.delayed(const Duration(seconds: 1), () {
        if (_shouldKeepListening && mounted) {
          _doListen();
        }
      });
    }
  }

  // ── 번역 ──────────────────────────────────────────────────────
  Future<void> _translateText(String text) async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final targetLang = lang.currentLanguage;

    // 한국어 설정이면 번역 불필요
    if (targetLang == 'ko') {
      if (mounted) {
        setState(() {
          _translatedText = text;
          _isTranslating = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isTranslating = true);

    try {
      final translated = await TranslationService.translate(
        text: text,
        targetLang: targetLang,
        sourceLang: 'ko',
      );
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('BridgeLive translate error: $e');
      if (mounted) {
        setState(() {
          _translatedText = text;
          _isTranslating = false;
        });
      }
    }
  }

  // ── 결과 초기화 ───────────────────────────────────────────────
  void _clearResults() {
    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _currentWords = '';
    });
  }

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.radio_button_checked, color: Color(0xFF4ECDC4), size: 16),
            SizedBox(width: 8),
            Text(
              'Bridge Live',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // 지우기 버튼
          if (_recognizedText.isNotEmpty || _translatedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              tooltip: '결과 지우기',
              onPressed: _clearResults,
            ),
        ],
      ),
      body: SafeArea(
        child: _isInitializing
            ? _buildInitializingView()
            : _micPermissionDenied
                ? _buildPermissionDeniedView()
                : !_speechAvailable
                    ? _buildUnavailableView()
                    : _buildMainView(lang),
      ),
    );
  }

  // ── 초기화 중 뷰 ───────────────────────────────────────────────
  Widget _buildInitializingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4ECDC4)),
          SizedBox(height: 16),
          Text(
            '마이크 초기화 중...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── 권한 거부 뷰 ──────────────────────────────────────────────
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              '마이크 권한이 필요합니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bridge Live를 사용하려면\n마이크 접근 권한을 허용해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('앱 설정 열기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 음성인식 불가 뷰 ──────────────────────────────────────────
  Widget _buildUnavailableView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hearing_disabled, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              '음성 인식을 사용할 수 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              '이 기기에서 음성 인식이 지원되지 않거나\n네트워크 연결을 확인해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── 메인 뷰 ───────────────────────────────────────────────────
  Widget _buildMainView(LanguageService lang) {
    final targetLangName = _getLangName(lang.currentLanguage);
    final isKorean = lang.currentLanguage == 'ko';

    return Column(
      children: [
        // ── 설명 배너 ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.translate, color: Color(0xFF4ECDC4), size: 18),
              const SizedBox(width: 8),
              Text(
                isKorean
                    ? '한국어로 말하면 그대로 표시됩니다'
                    : '한국어 인식 → $targetLangName 실시간 번역',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // ── 결과 영역 ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 인식 중 실시간 텍스트
                if (_isListening && _currentWords.isNotEmpty)
                  _buildResultCard(
                    label: '인식 중...',
                    text: _currentWords,
                    isLive: true,
                    labelColor: const Color(0xFF4ECDC4),
                  ),

                // 최종 인식 결과 (한국어)
                if (_recognizedText.isNotEmpty) ...[
                  _buildResultCard(
                    label: '인식된 한국어',
                    text: _recognizedText,
                    icon: Icons.record_voice_over,
                    labelColor: Colors.white70,
                  ),
                  const SizedBox(height: 16),
                ],

                // 번역 결과
                if (_isTranslating)
                  _buildResultCard(
                    label: '번역 중...',
                    text: '...',
                    isLive: true,
                    labelColor: const Color(0xFFFFD93D),
                  )
                else if (_translatedText.isNotEmpty && !isKorean)
                  _buildResultCard(
                    label: targetLangName,
                    text: _translatedText,
                    icon: Icons.translate,
                    labelColor: const Color(0xFFFFD93D),
                    isHighlighted: true,
                  ),

                // 아무 결과 없을 때 안내
                if (_recognizedText.isEmpty &&
                    _translatedText.isEmpty &&
                    (!_isListening || _currentWords.isEmpty))
                  _buildGuideView(lang),
              ],
            ),
          ),
        ),

        // ── 하단 컨트롤 ────────────────────────────────────────
        _buildControlBar(lang),
      ],
    );
  }

  Widget _buildGuideView(LanguageService lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mic,
                size: 48,
                color: Color(0xFF4ECDC4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '아래 버튼을 눌러 시작하세요',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '한국어로 말하면 자동으로 번역됩니다',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String label,
    required String text,
    bool isLive = false,
    bool isHighlighted = false,
    IconData? icon,
    Color labelColor = Colors.white70,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF1A1F40)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFD93D).withValues(alpha: 0.4)
              : isLive
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
          width: isHighlighted || isLive ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: labelColor),
                const SizedBox(width: 6),
              ] else if (isLive) ...[
                _LiveDot(),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: isHighlighted ? 20 : 16,
              color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.85),
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── 하단 컨트롤 바 ────────────────────────────────────────────
  Widget _buildControlBar(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태 텍스트
          Text(
            _isListening
                ? '음성 인식 중... 말씀해주세요'
                : _shouldKeepListening
                    ? '재시작 중...'
                    : '마이크 버튼을 눌러 시작',
            style: TextStyle(
              color: _isListening
                  ? const Color(0xFF4ECDC4)
                  : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 마이크 버튼
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
                border: Border.all(
                  color: const Color(0xFF4ECDC4),
                  width: 2,
                ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
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
        ],
      ),
    );
  }

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

// ── 깜박이는 라이브 점 위젯 ────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF4ECDC4),
        ),
      ),
    );
  }
}
