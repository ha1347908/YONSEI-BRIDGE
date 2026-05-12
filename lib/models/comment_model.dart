// Comment model - 댓글 데이터 모델

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorNationality;
  final String content;
  final String originalLanguage;

  /// 번역 캐시: { 'ko': '번역된 내용', 'en': 'translated content', ... }
  final Map<String, String> translations;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorNationality,
    required this.content,
    required this.originalLanguage,
    required this.createdAt,
    Map<String, String>? translations,
  }) : translations = translations ?? {};

  /// 특정 언어로 번역된 내용 (없으면 원문 반환)
  String contentFor(String lang) => translations[lang] ?? content;

  /// 해당 언어의 번역이 원문과 다른지 여부
  bool hasTranslationFor(String lang) =>
      translations.containsKey(lang) && lang != originalLanguage;

  factory Comment.fromFirestore(Map<String, dynamic> data, String docId) {
    // created_at 파싱
    DateTime createdAt;
    final raw = data['created_at'];
    if (raw == null) {
      createdAt = DateTime.now();
    } else {
      try {
        // Firestore Timestamp
        createdAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        createdAt = DateTime.now();
      }
    }

    // translations 파싱
    final rawTrans = data['translations'];
    final Map<String, String> parsedTrans = {};
    if (rawTrans is Map) {
      rawTrans.forEach((k, v) {
        parsedTrans[k.toString()] = v.toString();
      });
    }

    return Comment(
      id: data['comment_id'] as String? ?? docId,
      postId: data['post_id'] as String? ?? '',
      authorId: data['author_id'] as String? ?? '',
      authorName: data['author_name'] as String? ?? 'Unknown',
      authorNationality: data['author_nationality'] as String? ?? 'Unknown',
      content: data['content'] as String? ?? '',
      originalLanguage: data['original_language'] as String? ?? 'ko',
      createdAt: createdAt,
      translations: parsedTrans,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment_id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_nationality': authorNationality,
      'content': content,
      'original_language': originalLanguage,
      'translations': translations,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
