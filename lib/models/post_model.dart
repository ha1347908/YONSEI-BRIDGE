// Post model - 게시글 데이터 모델

/// 정보게시판 서브 카테고리
enum InfoCategory {
  mireaCampus,  // IN MIREA CAMPUS
  wonju,        // IN WONJU
  korea,        // IN KOREA
}

extension InfoCategoryExt on InfoCategory {
  String get id {
    switch (this) {
      case InfoCategory.mireaCampus: return 'mirea_campus';
      case InfoCategory.wonju:       return 'wonju';
      case InfoCategory.korea:       return 'korea';
    }
  }

  String get label {
    switch (this) {
      case InfoCategory.mireaCampus: return 'IN MIREA CAMPUS';
      case InfoCategory.wonju:       return 'IN WONJU';
      case InfoCategory.korea:       return 'IN KOREA';
    }
  }

  static InfoCategory fromId(String? id) {
    switch (id) {
      case 'mirea_campus': return InfoCategory.mireaCampus;
      case 'wonju':        return InfoCategory.wonju;
      case 'korea':        return InfoCategory.korea;
      default:             return InfoCategory.mireaCampus;
    }
  }
}

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
  });

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
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
