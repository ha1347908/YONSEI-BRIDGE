import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Google Translate API (free web endpoint)
  static const String _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  
  /// Translate text to target language
  /// 
  /// Supported language codes:
  /// - 'ko': Korean
  /// - 'en': English
  /// - 'ja': Japanese
  /// - 'zh-CN': Chinese (Simplified)
  /// - 'zh-TW': Chinese (Traditional)
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
        'tl': targetLang,
        'dt': 't',
        'q': text,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse != null && jsonResponse[0] != null) {
          String translatedText = '';
          for (var item in jsonResponse[0]) {
            if (item[0] != null) {
              translatedText += item[0];
            }
          }
          return translatedText;
        }
      }
      
      return text; // Return original if translation fails
    } catch (e) {
      return text; // Return original on error
    }
  }

  /// Detect language of text
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

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse != null && jsonResponse.length > 2) {
          return jsonResponse[2] ?? 'unknown';
        }
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get language name from code
  static String getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh-CN':
      case 'zh':
        return '简体中文';
      case 'zh-TW':
        return '繁體中文';
      default:
        return code;
    }
  }

  /// Convert app language code to Google Translate code
  static String convertToGoogleLangCode(String appLangCode) {
    switch (appLangCode) {
      case 'zh':
        return 'zh-CN';
      default:
        return appLangCode;
    }
  }
}
