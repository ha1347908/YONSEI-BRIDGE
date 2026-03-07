// Post model - 게시글 데이터 모델

/// 정보게시판 서브 카테고리
enum InfoCategory {
  mireaCampus, // IN MIREA CAMPUS
  wonju, // IN WONJU
  korea, // IN KOREA
}

extension InfoCategoryExt on InfoCategory {
  String get id {
    switch (this) {
      case InfoCategory.mireaCampus:
        return 'mirea_campus';
      case InfoCategory.wonju:
        return 'wonju';
      case InfoCategory.korea:
        return 'korea';
    }
  }

  String get label {
    switch (this) {
      case InfoCategory.mireaCampus:
        return 'IN MIREA CAMPUS';
      case InfoCategory.wonju:
        return 'IN WONJU';
      case InfoCategory.korea:
        return 'IN KOREA';
    }
  }

  static InfoCategory fromId(String? id) {
    switch (id) {
      case 'mirea_campus':
        return InfoCategory.mireaCampus;
      case 'wonju':
        return InfoCategory.wonju;
      case 'korea':
        return InfoCategory.korea;
      default:
        return InfoCategory.mireaCampus;
    }
  }
}

/// 앱 지원 언어 코드 목록
const List<String> kSupportedLangs = ['ko', 'en', 'ja', 'zh'];

class Post {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final DateTime createdAt;
  final String categoryId;
  final bool isAdminPost;
  final List<String>? imageUrls;
  final Map<String, dynamic>? targetFilters;

  /// 정보게시판 서브 카테고리 (info_board 전용)
  final InfoCategory? infoCategory;

  // ── 자동번역 필드 ─────────────────────────────────────
  /// 작성 원문 (원본 텍스트 – title + content 통합 저장 X, 별도 관리)
  final String? originalTitle;
  final String? originalContent;

  /// 작성 언어 코드 (예: 'ja', 'zh', 'en', 'ko')
  final String? originalLanguage;

  /// 번역 캐시 Map  { 'ko': {'title': '...', 'content': '...'}, 'en': {...} }
  final Map<String, Map<String, String>> translations;

  /// 번역 완료 여부 (백그라운드 번역 중 = false)
  final bool isTranslated;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.createdAt,
    required this.categoryId,
    this.isAdminPost = false,
    this.imageUrls,
    this.targetFilters,
    this.infoCategory,
    this.originalTitle,
    this.originalContent,
    this.originalLanguage,
    Map<String, Map<String, String>>? translations,
    this.isTranslated = false,
  }) : translations = translations ?? {};

  // ── 편의 getter ──────────────────────────────────────
  /// 번역본이 있는 언어 코드 목록
  List<String> get availableTranslationLangs => translations.keys.toList();

  /// 특정 언어로 번역된 제목 (없으면 원문 title 반환)
  String titleFor(String lang) =>
      translations[lang]?['title'] ?? title;

  /// 특정 언어로 번역된 내용 (없으면 원문 content 반환)
  String contentFor(String lang) =>
      translations[lang]?['content'] ?? content;

  /// 해당 언어가 원문과 다른지 (번역 토글 표시 여부)
  bool hasTranslationFor(String lang) =>
      translations.containsKey(lang) &&
      lang != (originalLanguage ?? 'ko');

  // ── 직렬화 ────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'author_id': authorId,
      'createdAt': createdAt.toIso8601String(),
      'categoryId': categoryId,
      'isAdminPost': isAdminPost,
      'imageUrls': imageUrls,
      'target_filters': targetFilters,
      'info_category': infoCategory?.id,
      'original_title': originalTitle ?? title,
      'original_content': originalContent ?? content,
      'original_language': originalLanguage ?? 'ko',
      'translations': translations.map(
        (lang, map) => MapEntry(lang, Map<String, String>.from(map)),
      ),
      'is_translated': isTranslated,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    // translations 파싱
    final rawTrans = map['translations'];
    final Map<String, Map<String, String>> parsedTrans = {};
    if (rawTrans is Map) {
      rawTrans.forEach((lang, val) {
        if (val is Map) {
          parsedTrans[lang.toString()] =
              val.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      });
    }

    return Post(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      author: map['author'] as String,
      authorId: map['author_id'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      categoryId: map['categoryId'] as String,
      isAdminPost: map['isAdminPost'] as bool? ?? false,
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>(),
      targetFilters: map['target_filters'] != null
          ? Map<String, dynamic>.from(map['target_filters'])
          : null,
      infoCategory: map['info_category'] != null
          ? InfoCategoryExt.fromId(map['info_category'] as String?)
          : null,
      originalTitle: map['original_title'] as String?,
      originalContent: map['original_content'] as String?,
      originalLanguage: map['original_language'] as String?,
      translations: parsedTrans,
      isTranslated: map['is_translated'] as bool? ?? false,
    );
  }

  /// 번역 결과를 반영한 새 Post 복사본 반환
  Post copyWithTranslations({
    required Map<String, Map<String, String>> newTranslations,
    bool translated = true,
  }) {
    return Post(
      id: id,
      title: title,
      content: content,
      author: author,
      authorId: authorId,
      createdAt: createdAt,
      categoryId: categoryId,
      isAdminPost: isAdminPost,
      imageUrls: imageUrls,
      targetFilters: targetFilters,
      infoCategory: infoCategory,
      originalTitle: originalTitle ?? title,
      originalContent: originalContent ?? content,
      originalLanguage: originalLanguage,
      translations: newTranslations,
      isTranslated: translated,
    );
  }
}
