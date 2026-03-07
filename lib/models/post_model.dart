// Post model - 게시글 데이터 모델
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
      targetFilters: map['target_filters'] != null ? Map<String, dynamic>.from(map['target_filters']) : null,
    );
  }
}
