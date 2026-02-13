import 'package:cloud_firestore/cloud_firestore.dart';

/// Post category enumeration
enum PostCategory {
  freeBoard,
  livingSetup,
  transportation,
  usefulInfo,
  campusInfo,
  needJob,
  hospitalInfo,
  restaurants,
  clubs,
  koreanExchange,
  about,
}

/// Post model for YONSEI BRIDGE application
class PostModel {
  final String postId;
  final String title;
  final String content;
  final PostCategory category;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isNotice;
  final bool isDeleted;
  final List<String> images;
  final List<String> tags;

  PostModel({
    required this.postId,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isNotice = false,
    this.isDeleted = false,
    this.images = const [],
    this.tags = const [],
  });

  /// Convert PostCategory enum to string
  static String categoryToString(PostCategory category) {
    switch (category) {
      case PostCategory.freeBoard:
        return 'free_board';
      case PostCategory.livingSetup:
        return 'living_setup';
      case PostCategory.transportation:
        return 'transportation';
      case PostCategory.usefulInfo:
        return 'useful_info';
      case PostCategory.campusInfo:
        return 'campus_info';
      case PostCategory.needJob:
        return 'need_job';
      case PostCategory.hospitalInfo:
        return 'hospital_info';
      case PostCategory.restaurants:
        return 'restaurants';
      case PostCategory.clubs:
        return 'clubs';
      case PostCategory.koreanExchange:
        return 'korean_exchange';
      case PostCategory.about:
        return 'about';
    }
  }

  /// Convert string to PostCategory enum
  static PostCategory stringToCategory(String category) {
    switch (category) {
      case 'free_board':
        return PostCategory.freeBoard;
      case 'living_setup':
        return PostCategory.livingSetup;
      case 'transportation':
        return PostCategory.transportation;
      case 'useful_info':
        return PostCategory.usefulInfo;
      case 'campus_info':
        return PostCategory.campusInfo;
      case 'need_job':
        return PostCategory.needJob;
      case 'hospital_info':
        return PostCategory.hospitalInfo;
      case 'restaurants':
        return PostCategory.restaurants;
      case 'clubs':
        return PostCategory.clubs;
      case 'korean_exchange':
        return PostCategory.koreanExchange;
      case 'about':
        return PostCategory.about;
      default:
        return PostCategory.freeBoard;
    }
  }

  /// Get category ID string for matching with BoardCategory
  String getCategoryId() {
    return categoryToString(category);
  }

  /// Create PostModel from Firestore document
  factory PostModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PostModel(
      postId: data['post_id'] as String? ?? documentId,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      category: stringToCategory(data['category'] as String? ?? 'free_board'),
      authorId: data['author_id'] as String? ?? '',
      authorName: data['author_name'] as String? ?? 'Unknown',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: (data['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (data['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (data['comment_count'] as num?)?.toInt() ?? 0,
      isNotice: data['is_notice'] as bool? ?? false,
      isDeleted: data['is_deleted'] as bool? ?? false,
      images: (data['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  /// Convert PostModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'post_id': postId,
      'title': title,
      'content': content,
      'category': categoryToString(category),
      'author_id': authorId,
      'author_name': authorName,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_notice': isNotice,
      'is_deleted': isDeleted,
      'images': images,
      'tags': tags,
    };
  }

  /// Increment view count
  PostModel incrementViewCount() {
    return copyWith(viewCount: viewCount + 1);
  }

  /// Increment like count
  PostModel incrementLikeCount() {
    return copyWith(likeCount: likeCount + 1);
  }

  /// Decrement like count
  PostModel decrementLikeCount() {
    return copyWith(likeCount: likeCount > 0 ? likeCount - 1 : 0);
  }

  /// Increment comment count
  PostModel incrementCommentCount() {
    return copyWith(commentCount: commentCount + 1);
  }

  /// Copy with method
  PostModel copyWith({
    String? postId,
    String? title,
    String? content,
    PostCategory? category,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    bool? isNotice,
    bool? isDeleted,
    List<String>? images,
    List<String>? tags,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isNotice: isNotice ?? this.isNotice,
      isDeleted: isDeleted ?? this.isDeleted,
      images: images ?? this.images,
      tags: tags ?? this.tags,
    );
  }
}
