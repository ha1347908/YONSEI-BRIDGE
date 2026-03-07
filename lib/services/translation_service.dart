import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

/// Google Translate 무료 엔드포인트 기반 번역 서비스
/// - 게시글 작성 시 자동번역 (4개 언어: ko / en / ja / zh)
/// - SharedPreferences 캐시로 중복 API 호출 방지
class TranslationService {
  static const String _baseUrl =
      'https://translate.googleapis.com/translate_a/single';

  /// 지원 언어 코드 → Google Translate 코드 매핑
  static String _toGoogleCode(String appCode) {
    switch (appCode) {
      case 'zh':
        return 'zh-CN';
      default:
        return appCode;
    }
  }

  // ─────────────────────────────────────────────────────
  // 기본 번역 API
  // ─────────────────────────────────────────────────────

  /// [text] → [targetLang] 번역. 실패 시 원문 반환.
  static Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    if (text.trim().isEmpty) return text;
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': sourceLang,
        'tl': _toGoogleCode(targetLang),
        'dt': 't',
        'q': text,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final j = json.decode(res.body);
        if (j != null && j[0] != null) {
          return (j[0] as List)
              .map((item) => item[0] ?? '')
              .join();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('TranslationService.translate error: $e');
    }
    return text;
  }

  /// 언어 자동 감지. 실패 시 'unknown' 반환.
  static Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'unknown';
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'auto',
        'tl': 'en',
        'dt': 't',
        'q': text,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final j = json.decode(res.body);
        if (j != null && j.length > 2) return j[2] ?? 'unknown';
      }
    } catch (_) {}
    return 'unknown';
  }

  // ─────────────────────────────────────────────────────
  // 게시글 자동번역 (On-Create Trigger 역할)
  // ─────────────────────────────────────────────────────

  /// 게시글 등록 직후 백그라운드 번역 수행.
  /// 원문 언어를 제외한 나머지 3개 언어로 번역 후
  /// SharedPreferences의 해당 게시글 데이터를 업데이트한다.
  ///
  /// [post]      : 방금 저장된 Post
  /// [prefs]     : SharedPreferences 인스턴스
  /// [postsKey]  : 예) 'posts_free_board'
  static Future<Post> translatePostAndCache({
    required Post post,
    required SharedPreferences prefs,
    required String postsKey,
  }) async {
    // ① 원문 언어 감지
    final srcLang = await detectLanguage('${post.title} ${post.content}');
    final detectedLang = _normalizeDetected(srcLang);

    // ② 번역할 대상 언어 = 지원 4개 중 원문 언어 제외
    final targets =
        kSupportedLangs.where((l) => l != detectedLang).toList();

    // ③ 병렬 번역
    final Map<String, Map<String, String>> newTrans = {};
    await Future.wait(targets.map((lang) async {
      final tTitle = await translate(
        text: post.title,
        targetLang: lang,
        sourceLang: detectedLang == 'unknown' ? 'auto' : detectedLang,
      );
      final tContent = await translate(
        text: post.content,
        targetLang: lang,
        sourceLang: detectedLang == 'unknown' ? 'auto' : detectedLang,
      );
      newTrans[lang] = {'title': tTitle, 'content': tContent};
    }));

    // ④ Post 복사본 생성
    final translated = post.copyWithTranslations(
      newTranslations: newTrans,
      translated: true,
    );

    // ⑤ SharedPreferences 업데이트 (해당 게시글만 교체)
    await _updatePostInPrefs(
      prefs: prefs,
      postsKey: postsKey,
      postId: post.id,
      detectedLang: detectedLang,
      translations: newTrans,
    );

    return translated;
  }

  /// SharedPreferences 내 해당 게시글에 번역 데이터 병합
  static Future<void> _updatePostInPrefs({
    required SharedPreferences prefs,
    required String postsKey,
    required String postId,
    required String detectedLang,
    required Map<String, Map<String, String>> translations,
  }) async {
    try {
      final raw = prefs.getString(postsKey) ?? '[]';
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item['post_id'] == postId) {
          item['original_language'] = detectedLang;
          item['translations'] = translations;
          item['is_translated'] = true;
          break;
        }
      }
      await prefs.setString(postsKey, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) debugPrint('_updatePostInPrefs error: $e');
    }
  }

  /// 감지된 언어 코드 정규화 ('zh-CN' → 'zh' 등)
  static String _normalizeDetected(String code) {
    if (code.startsWith('zh')) return 'zh';
    if (code == 'unknown') return 'ko'; // 감지 실패 시 한국어 기본
    return code;
  }

  // ─────────────────────────────────────────────────────
  // 유틸
  // ─────────────────────────────────────────────────────

  static String getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh':
      case 'zh-CN':
        return '简体中文';
      default:
        return code;
    }
  }

  static String convertToGoogleLangCode(String appLangCode) {
    return _toGoogleCode(appLangCode);
  }
}
