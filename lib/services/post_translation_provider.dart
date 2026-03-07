import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/translation_service.dart';

/// 게시글 상세 화면에서 "원문 ↔ 번역" 토글 상태를 관리하는 Provider
///
/// 사용 방법:
///   ChangeNotifierProvider(create: (_) => PostTranslationProvider(post, appLang))
class PostTranslationProvider extends ChangeNotifier {
  final Post _post;
  final String _appLang; // 현재 유저 언어 코드

  bool _showOriginal = false; // false = 번역 보기 (기본), true = 원문 보기
  bool _isTranslating = false;
  String? _error;

  // 런타임 번역 결과 (DB에 없을 때 온-더-플라이 번역)
  Map<String, Map<String, String>> _runtimeTranslations = {};

  PostTranslationProvider(this._post, this._appLang) {
    _runtimeTranslations = Map.from(_post.translations);
    // 번역이 아직 없고 원문 언어 ≠ 앱 언어라면 즉시 번역 시도
    if (!_post.isTranslated &&
        _post.originalLanguage != null &&
        _post.originalLanguage != _appLang) {
      _translateNow();
    }
  }

  // ─── getters ───────────────────────────────────────────
  bool get showOriginal => _showOriginal;
  bool get isTranslating => _isTranslating;
  String? get error => _error;

  /// 번역 토글 버튼을 표시해야 하는지
  /// (원문 언어 ≠ 앱 언어이고, 번역본이 있을 때)
  bool get canToggle {
    final origLang = _post.originalLanguage ?? 'ko';
    return origLang != _appLang &&
        (_runtimeTranslations.containsKey(_appLang) || _isTranslating);
  }

  /// 현재 보여줄 제목
  String get displayTitle {
    if (_showOriginal) return _post.originalTitle ?? _post.title;
    return _runtimeTranslations[_appLang]?['title'] ?? _post.title;
  }

  /// 현재 보여줄 내용
  String get displayContent {
    if (_showOriginal) return _post.originalContent ?? _post.content;
    return _runtimeTranslations[_appLang]?['content'] ?? _post.content;
  }

  /// 토글 버튼 라벨
  String get toggleLabel =>
      _showOriginal ? 'see_translation' : 'see_original';

  /// 원문 언어 이름 (예: '日本語')
  String get originalLanguageName =>
      TranslationService.getLanguageName(_post.originalLanguage ?? 'ko');

  // ─── actions ──────────────────────────────────────────
  void toggleView() {
    _showOriginal = !_showOriginal;
    notifyListeners();
  }

  Future<void> _translateNow() async {
    if (_isTranslating) return;
    _isTranslating = true;
    _error = null;
    notifyListeners();

    try {
      final srcLang = _post.originalLanguage ?? 'auto';
      final tTitle = await TranslationService.translate(
        text: _post.originalTitle ?? _post.title,
        targetLang: _appLang,
        sourceLang: srcLang,
      );
      final tContent = await TranslationService.translate(
        text: _post.originalContent ?? _post.content,
        targetLang: _appLang,
        sourceLang: srcLang,
      );
      _runtimeTranslations[_appLang] = {
        'title': tTitle,
        'content': tContent,
      };
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('PostTranslationProvider error: $e');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// 외부에서 번역 재시도 호출
  void retryTranslation() => _translateNow();
}
