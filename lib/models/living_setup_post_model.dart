import 'package:cloud_firestore/cloud_firestore.dart';

/// Living Setup Post Target Filters
class PostTargetFilter {
  final List<String> studentTypes;    // ['degree', 'exchange']
  final List<String> housingTypes;    // ['dormitory', 'studio', 'other']
  final List<String> koreanLevels;    // ['no_topik', 'level_1_2', 'level_3_4', 'level_5_6']
  final List<String> visaTypes;       // Visa type IDs
  final List<String> departments;     // Department IDs
  
  PostTargetFilter({
    this.studentTypes = const [],
    this.housingTypes = const [],
    this.koreanLevels = const [],
    this.visaTypes = const [],
    this.departments = const [],
  });
  
  factory PostTargetFilter.fromMap(Map<String, dynamic> map) {
    return PostTargetFilter(
      studentTypes: (map['student_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      housingTypes: (map['housing_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      koreanLevels: (map['korean_levels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      visaTypes: (map['visa_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      departments: (map['departments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'student_types': studentTypes,
      'housing_types': housingTypes,
      'korean_levels': koreanLevels,
      'visa_types': visaTypes,
      'departments': departments,
    };
  }
  
  bool get hasFilters {
    return studentTypes.isNotEmpty ||
           housingTypes.isNotEmpty ||
           koreanLevels.isNotEmpty ||
           visaTypes.isNotEmpty ||
           departments.isNotEmpty;
  }
}

/// Living Setup Post Model
class LivingSetupPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final PostTargetFilter targetFilter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int likeCount;
  
  LivingSetupPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.targetFilter,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
  });
  
  factory LivingSetupPost.fromFirestore(Map<String, dynamic> data, String documentId) {
    return LivingSetupPost(
      id: documentId,
      authorId: data['author_id'] as String? ?? '',
      authorName: data['author_name'] as String? ?? 'Unknown',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      targetFilter: PostTargetFilter.fromMap(data['target_filter'] as Map<String, dynamic>? ?? {}),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['view_count'] as int? ?? 0,
      likeCount: data['like_count'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'author_id': authorId,
      'author_name': authorName,
      'title': title,
      'content': content,
      'target_filter': targetFilter.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'view_count': viewCount,
      'like_count': likeCount,
    };
  }
}
