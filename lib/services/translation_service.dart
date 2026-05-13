import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

// ─────────────────────────────────────────────────────
// 번역 API 출처 열거형 및 결과 클래스
// ─────────────────────────────────────────────────────

enum TranslationSource {
  myMemory,   // MyMemory API
  googleGtx,  // Google GTX 비공식 엔드포인트
  failed,     // 모든 API 실패 → 원문 반환
  none,       // 번역 불필요 (빈 텍스트 등)
}

class TranslationResult {
  final String text;
  final TranslationSource source;

  const TranslationResult({
    required this.text,
    required this.source,
  });
}

/// 번역 서비스
/// - 1순위: MyMemory API (CORS 완전 지원, 무료, 인증 불필요)
/// - 2순위: Google GTX 비공식 엔드포인트 (네이티브 앱 / 서버사이드 fallback)
/// - 게시글 작성 시 자동번역 (4개 언어: ko / en / ja / zh)
class TranslationService {
  // MyMemory: CORS 허용, 무료, API키 불필요
  static const String _myMemoryUrl = 'https://api.mymemory.translated.net/get';
  // Google GTX: CORS 없음 → 네이티브/서버에서만 동작
  static const String _googleGtxUrl =
      'https://translate.googleapis.com/translate_a/single';

  /// 앱 언어코드 → MyMemory 언어쌍 코드 변환
  static String _toMyMemoryLang(String appCode) {
    switch (appCode) {
      case 'zh': return 'zh-CN';
      case 'ko': return 'ko';
      case 'en': return 'en';
      case 'ja': return 'ja';
      default:   return appCode;
    }
  }

  /// 앱 언어코드 → Google 코드 변환
  static String _toGoogleCode(String appCode) {
    switch (appCode) {
      case 'zh': return 'zh-CN';
      default:   return appCode;
    }
  }

  // ─────────────────────────────────────────────────────
  // 기본 번역 API
  // ─────────────────────────────────────────────────────

  /// [text] → [targetLang] 번역. 실패 시 원문 반환.
  /// 웹(Flutter Web): MyMemory 사용 (CORS 지원)
  /// 네이티브: MyMemory → Google GTX 순서로 fallback
  /// 번역 결과 (텍스트 + 사용된 API 출처)
  static Future<TranslationResult> translateWithSource({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    if (text.trim().isEmpty) return TranslationResult(text: text, source: TranslationSource.none);

    // ① MyMemory API (CORS 완전 지원)
    try {
      final src = sourceLang == 'auto' ? 'ko' : _toMyMemoryLang(sourceLang);
      final tgt = _toMyMemoryLang(targetLang);
      final uri = Uri.parse(_myMemoryUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$src|$tgt',
        'de': 'yonseibridge@app.com',
      });
      final res = await http.get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final j = json.decode(res.body) as Map<String, dynamic>;
        final translated = j['responseData']?['translatedText'] as String?;
        if (j['responseStatus'] == 200 &&
            translated != null &&
            translated.isNotEmpty &&
            translated.toUpperCase() != text.toUpperCase()) {
          if (kDebugMode) debugPrint('[Translation] MyMemory OK');
          return TranslationResult(text: translated, source: TranslationSource.myMemory);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Translation] MyMemory error: $e');
    }

    // ② Google GTX fallback
    try {
      final uri = Uri.parse(_googleGtxUrl).replace(queryParameters: {
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
          final result = (j[0] as List).map((item) => item[0] ?? '').join();
          if (result.isNotEmpty) {
            if (kDebugMode) debugPrint('[Translation] Google GTX OK');
            return TranslationResult(text: result, source: TranslationSource.googleGtx);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Translation] Google GTX error: $e');
    }

    return TranslationResult(text: text, source: TranslationSource.failed);
  }

  /// 기존 호환용 — 텍스트만 반환 (내부적으로 translateWithSource 호출)
  static Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final result = await translateWithSource(
      text: text, targetLang: targetLang, sourceLang: sourceLang,
    );
    return result.text;
  }

  /// 언어 자동 감지. 실패 시 'unknown' 반환.
  static Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) return 'unknown';
    try {
      // MyMemory로 en 번역 시도 → responseData.match로 감지
      final uri = Uri.parse(_myMemoryUrl).replace(queryParameters: {
        'q': text,
        'langpair': 'autodetect|en',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      // MyMemory는 감지 언어를 직접 반환하지 않으므로 Google GTX로 fallback
      if (res.statusCode != 200) throw Exception('status ${res.statusCode}');
    } catch (_) {}

    // Google GTX로 감지 시도 (네이티브에서만 동작)
    try {
      final uri = Uri.parse(_googleGtxUrl).replace(queryParameters: {
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

  static String convertToMyMemoryLangCode(String appLangCode) {
    return _toMyMemoryLang(appLangCode);
  }
}
