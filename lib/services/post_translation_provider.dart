import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/translation_service.dart';
import '../services/firestore_service.dart';

/// 게시글 상세 화면에서 "원문 ↔ 번역" 토글 상태를 관리하는 Provider
///
/// 핵심 동작:
///  - sourceLang 항상 'auto' → Google이 원문 언어를 직접 감지
///  - 번역본이 없거나 유효하지 않으면 자동 번역 수행
///  - 번역 완료 후 Firestore에 결과 저장 (다음 방문 시 캐시 활용)
///  - 원문 언어 == 앱 언어인 경우 번역 토글 숨김 (같은 언어끼리 번역 불필요)
class PostTranslationProvider extends ChangeNotifier {
  final Post _post;
  final String _appLang; // 현재 유저 언어 코드 (ko/en/ja/zh)
  final FirestoreService _fs;

  bool _showOriginal = false;
  bool _isTranslating = false;
  String? _error;

  Map<String, Map<String, String>> _runtimeTranslations = {};

  PostTranslationProvider(this._post, this._appLang, this._fs) {
    _runtimeTranslations = Map.from(_post.translations);

    // 원문 언어 감지
    final originalLang = _post.originalLanguage;

    // 앱 언어와 원문 언어가 같으면 번역 불필요
    if (originalLang != null &&
        originalLang != 'unknown' &&
        originalLang != 'auto' &&
        _normalizeLanguage(originalLang) == _normalizeLanguage(_appLang)) {
      // 같은 언어 → 번역 필요 없음
      return;
    }

    final sourceTitle = _post.originalTitle ?? _post.title;

    // 앱 언어로 된 번역본이 있고 유효한지 확인
    final existingTitle = _runtimeTranslations[_appLang]?['title'] ?? '';
    final existingContent = _runtimeTranslations[_appLang]?['content'] ?? '';

    // 번역본이 없거나 원문과 동일하면 번역 시도
    final hasValidTranslation = existingTitle.isNotEmpty &&
        existingTitle != sourceTitle &&
        existingContent.isNotEmpty;

    if (!hasValidTranslation) {
      _translateNow();
    }
  }

  bool get showOriginal => _showOriginal;
  bool get isTranslating => _isTranslating;
  String? get error => _error;

  /// 언어 코드 정규화 (zh-CN → zh, zh-TW → zh 등)
  String _normalizeLanguage(String lang) {
    if (lang.startsWith('zh')) return 'zh';
    return lang;
  }

  /// 번역 토글 버튼 표시 여부
  bool get canToggle {
    if (_isTranslating) return true;

    // 원문 언어와 앱 언어가 같으면 토글 불필요
    final originalLang = _post.originalLanguage;
    if (originalLang != null &&
        originalLang != 'unknown' &&
        originalLang != 'auto' &&
        _normalizeLanguage(originalLang) == _normalizeLanguage(_appLang)) {
      return false;
    }

    final translated = _runtimeTranslations[_appLang];
    if (translated == null) return false;
    final translatedTitle = translated['title'] ?? '';
    if (translatedTitle.isEmpty) return false;

    // 번역 결과가 원문과 다를 때만 토글 표시
    final sourceTitle = _post.originalTitle ?? _post.title;
    return translatedTitle != sourceTitle;
  }

  /// 현재 보여줄 제목
  String get displayTitle {
    if (_showOriginal) return _post.originalTitle ?? _post.title;
    final translated = _runtimeTranslations[_appLang]?['title'];
    if (translated != null && translated.isNotEmpty) return translated;
    return _post.originalTitle ?? _post.title;
  }

  /// 현재 보여줄 내용
  String get displayContent {
    if (_showOriginal) return _post.originalContent ?? _post.content;
    final translated = _runtimeTranslations[_appLang]?['content'];
    if (translated != null && translated.isNotEmpty) return translated;
    return _post.originalContent ?? _post.content;
  }

  String get toggleLabel =>
      _showOriginal ? 'see_translation' : 'see_original';

  String get originalLanguageName =>
      TranslationService.getLanguageName(_post.originalLanguage ?? 'ko');

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
      // 항상 'auto' 사용: Google이 원문 언어를 자동 감지
      const srcLang = 'auto';

      final sourceTitle = _post.originalTitle ?? _post.title;
      final sourceContent = _post.originalContent ?? _post.content;

      if (sourceTitle.trim().isEmpty && sourceContent.trim().isEmpty) {
        _isTranslating = false;
        notifyListeners();
        return;
      }

      final tTitle = await TranslationService.translate(
        text: sourceTitle,
        targetLang: _appLang,
        sourceLang: srcLang,
      );
      final tContent = await TranslationService.translate(
        text: sourceContent,
        targetLang: _appLang,
        sourceLang: srcLang,
      );

      // 번역 결과가 원문과 다른 경우에만 저장
      if (tTitle != sourceTitle || tContent != sourceContent) {
        _runtimeTranslations[_appLang] = {
          'title': tTitle,
          'content': tContent,
        };

        // 원문 언어 감지 (번역 시 함께 저장)
        String detectedLang = _post.originalLanguage ?? 'auto';
        if (detectedLang == 'auto' || detectedLang.isEmpty) {
          detectedLang = await TranslationService.detectLanguage(sourceTitle);
          if (detectedLang.startsWith('zh')) detectedLang = 'zh';
          if (detectedLang == 'unknown') detectedLang = 'ko';
        }

        // Firestore에 번역 결과 저장 (캐시)
        if (_post.id.isNotEmpty) {
          await _fs.updatePostTranslations(
            postId: _post.id,
            translations: Map.from(_runtimeTranslations),
            originalLanguage: detectedLang,
          );
        }
      } else {
        // 번역 결과가 원문과 같은 경우 (같은 언어로 번역된 경우)
        // 그냥 원문 저장
        _runtimeTranslations[_appLang] = {
          'title': tTitle,
          'content': tContent,
        };
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('PostTranslationProvider._translateNow error: $e');
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  void retryTranslation() => _translateNow();
}
