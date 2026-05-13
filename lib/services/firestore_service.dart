import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Centralised Firestore data access layer.
///
/// Collections:
///   users        – registered user profiles & status
///   posts        – info-board and free-board posts
///   saved_posts  – per-user bookmarked posts
///   recovery_requests – account recovery submissions
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usersCol =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get postsCol =>
      _db.collection('posts');
  CollectionReference<Map<String, dynamic>> get recoveryCol =>
      _db.collection('recovery_requests');

  // ── Helper: saved-posts sub-collection path ──────────────────────────────
  CollectionReference<Map<String, dynamic>> savedPostsCol(String userId) =>
      _db.collection('users').doc(userId).collection('saved_posts');

  // ════════════════════════════════════════════════════════════════════════
  // USERS
  // ════════════════════════════════════════════════════════════════════════

  /// Create / overwrite a user document after signup.
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String nickname,
    required String nationality,
    required String contact,
    String status = 'Pending',
    String role = 'User',
    String permission = 'user',
    String? password,
    String? idPhotoBase64,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'nickname': nickname,
      'nationality': nationality,
      'contact': contact,
      'status': status,
      'role': role,
      'permission': permission,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (password != null) data['password'] = password;
    if (idPhotoBase64 != null) data['id_photo_base64'] = idPhotoBase64;
    await usersCol.doc(uid).set(data);
  }

  /// Fetch a single user document.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await usersCol.doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Fetch user by email (for login / recovery flows).
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snap = await usersCol
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// Update user status (Pending → Approved / Rejected / Blocked).
  Future<void> updateUserStatus(String uid, String status,
      {String? reason}) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (reason != null) data['status_reason'] = reason;
    await usersCol.doc(uid).update(data);
  }

  /// Stream all users (for admin approval screen).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers({String? status}) {
    if (status != null && status != 'All') {
      return usersCol
          .where('status', isEqualTo: status)
          .snapshots();
    }
    return usersCol.snapshots();
  }

  /// 승인된 사용자 목록 단건 조회 (관리자 메시지 발송용)
  Future<List<Map<String, dynamic>>> getApprovedUsers() async {
    final snap = await usersCol
        .where('status', isEqualTo: 'Approved')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['uid'] = d.id;
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  // POSTS
  // ════════════════════════════════════════════════════════════════════════

  /// Create a new post.
  Future<String> createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    required String boardType, // 'info' | 'free'
    String? infoCategory,      // 'mirea' | 'wonju' | 'korea'
    List<String> imageUrls = const [],
    Map<String, Map<String, String>> translations = const {},
    String originalLanguage = 'ko',
  }) async {
    final ref = postsCol.doc();
    await ref.set({
      'post_id': ref.id,
      'title': title,
      'content': content,
      'original_title': title,
      'original_content': content,
      'author_id': authorId,
      'author_name': authorName,
      'board_type': boardType,
      'info_category': infoCategory,
      'image_urls': imageUrls,
      'translations': translations,
      'original_language': originalLanguage,
      'is_translated': translations.isNotEmpty,
      'view_count': 0,
      'comment_count': 0,
      'save_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_deleted': false,
    });
    return ref.id;
  }

  /// Stream posts filtered by board type (and optionally info category).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPosts({
    required String boardType,
    String? infoCategory,
  }) {
    Query<Map<String, dynamic>> q =
        postsCol.where('board_type', isEqualTo: boardType)
                .where('is_deleted', isEqualTo: false);
    if (infoCategory != null) {
      q = q.where('info_category', isEqualTo: infoCategory);
    }
    return q.snapshots();
  }

  /// Fetch posts with document ID guaranteed in post_id field.
  Future<List<Map<String, dynamic>>> getPostsWithId({
    required String boardType,
    String? infoCategory,
  }) => getPosts(boardType: boardType, infoCategory: infoCategory);

  /// Fetch posts once (for initial load).
  Future<List<Map<String, dynamic>>> getPosts({
    required String boardType,
    String? infoCategory,
  }) async {
    Query<Map<String, dynamic>> q =
        postsCol.where('board_type', isEqualTo: boardType)
                .where('is_deleted', isEqualTo: false);
    if (infoCategory != null) {
      q = q.where('info_category', isEqualTo: infoCategory);
    }
    final snap = await q.get();
    // post_id 필드가 없는 구문서도 문서 ID로 보완
    final posts = snap.docs.map((d) {
      final data = d.data();
      if (data['post_id'] == null || (data['post_id'] as String).isEmpty) {
        data['post_id'] = d.id;
      }
      return data;
    }).toList();
    // Sort in memory to avoid composite index requirement
    posts.sort((a, b) {
      final aTime = a['created_at'];
      final bTime = b['created_at'];
      if (aTime == null || bTime == null) return 0;
      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });
    return posts;
  }

  /// Soft-delete a post.
  Future<void> deletePost(String postId) async {
    await postsCol.doc(postId).update({
      'is_deleted': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// 게시글 고정/고정해제
  Future<void> pinPost(String postId, bool pin) async {
    await postsCol.doc(postId).update({
      'is_pinned': pin,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// 정보게시판 게시글 순서 일괄 업데이트
  /// [orders] = { postId: sortOrder, ... }
  Future<void> updateInfoPostOrders(Map<String, int> orders) async {
    final batch = _db.batch();
    orders.forEach((postId, order) {
      batch.update(postsCol.doc(postId), {
        'sort_order': order,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
  }

  /// Increment view count.
  Future<void> incrementViewCount(String postId) async {
    await postsCol.doc(postId).update({
      'view_count': FieldValue.increment(1),
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // SAVED POSTS (per-user sub-collection)
  // ════════════════════════════════════════════════════════════════════════

  Future<void> savePost(String userId, String postId,
      Map<String, dynamic> postData) async {
    await savedPostsCol(userId).doc(postId).set({
      ...postData,
      'saved_at': FieldValue.serverTimestamp(),
    });
    // Increment save_count on the post document
    await postsCol.doc(postId).update({
      'save_count': FieldValue.increment(1),
    });
  }

  Future<void> unsavePost(String userId, String postId) async {
    await savedPostsCol(userId).doc(postId).delete();
    await postsCol.doc(postId).update({
      'save_count': FieldValue.increment(-1),
    });
  }

  Future<bool> isPostSaved(String userId, String postId) async {
    final doc = await savedPostsCol(userId).doc(postId).get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getSavedPosts(String userId) async {
    final snap = await savedPostsCol(userId).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNT RECOVERY REQUESTS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> submitRecoveryRequest(String email) async {
    await recoveryCol.doc(email).set({
      'email': email,
      'status': 'Pending',
      'requested_at': FieldValue.serverTimestamp(),
      'read_by_admin': false,
    });
  }

  Future<void> markRecoveryRead(String email) async {
    await recoveryCol.doc(email).update({'read_by_admin': true});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingRecovery() {
    return recoveryCol
        .where('status', isEqualTo: 'Pending')
        .snapshots();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ANALYTICS HELPERS
  // ════════════════════════════════════════════════════════════════════════

  /// Count users by status.
  Future<Map<String, int>> getUserStatusCounts() async {
    final snap = await usersCol.get();
    final counts = <String, int>{
      'Pending': 0, 'Approved': 0, 'Rejected': 0, 'Blocked': 0,
    };
    for (final doc in snap.docs) {
      final s = doc.data()['status'] as String? ?? 'Unknown';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  /// Top posts by view count (info board).
  Future<List<Map<String, dynamic>>> getTopInfoPosts({int limit = 5}) async {
    final snap = await postsCol
        .where('board_type', isEqualTo: 'info')
        .where('is_deleted', isEqualTo: false)
        .get();
    final posts = snap.docs.map((d) => d.data()).toList();
    posts.sort((a, b) =>
        ((b['view_count'] as num?) ?? 0)
            .compareTo((a['view_count'] as num?) ?? 0));
    return posts.take(limit).toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHAT (1:1 사용자 ↔ 관리자)
  //
  // Firestore 구조:
  //   chats/{userId}/                  ← 채팅방 문서 (메타)
  //   chats/{userId}/messages/{msgId}  ← 메시지 서브컬렉션
  // ════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get chatsCol =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> messagesCol(String userId) =>
      chatsCol.doc(userId).collection('messages');

  /// 채팅방 문서 생성 또는 갱신 (첫 메시지 전송 시 자동 호출)
  Future<void> _ensureChatRoom(String userId, String userName) async {
    final doc = await chatsCol.doc(userId).get();
    if (!doc.exists) {
      await chatsCol.doc(userId).set({
        'user_id':   userId,
        'user_name': userName,
        'created_at': FieldValue.serverTimestamp(),
        'last_message': '',
        'last_message_at': FieldValue.serverTimestamp(),
        'unread_by_admin': 0,
        'unread_by_user':  0,
      });
    }
  }

  /// 메시지 전송
  /// [senderRole] : 'user' | 'admin'
  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    await _ensureChatRoom(userId, userName);

    // 메시지 문서 추가
    await messagesCol(userId).add({
      'sender_id':   senderId,
      'sender_name': senderName,
      'sender_role': senderRole,  // 'user' | 'admin'
      'text':        text,
      'created_at':  FieldValue.serverTimestamp(),
      'read':        false,
    });

    // 채팅방 메타 갱신
    await chatsCol.doc(userId).update({
      'last_message':    text,
      'last_message_at': FieldValue.serverTimestamp(),
      // 읽지 않은 카운트 증가 (상대방 기준)
      if (senderRole == 'user')  'unread_by_admin': FieldValue.increment(1),
      if (senderRole == 'admin') 'unread_by_user':  FieldValue.increment(1),
    });
  }

  /// 메시지 실시간 스트림 (최신순 정렬은 클라이언트에서)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String userId) {
    return messagesCol(userId)
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  /// 관리자용: 전체 채팅방 목록 (최근 메시지 순)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllChatRooms() {
    return chatsCol.orderBy('last_message_at', descending: true).snapshots();
  }

  /// 읽음 처리 — 관리자가 읽으면 unread_by_admin = 0
  Future<void> markReadByAdmin(String userId) async {
    await chatsCol.doc(userId).update({'unread_by_admin': 0});
  }

  /// 읽음 처리 — 사용자가 읽으면 unread_by_user = 0
  Future<void> markReadByUser(String userId) async {
    await chatsCol.doc(userId).update({'unread_by_user': 0});
  }

  /// 사용자의 읽지 않은 메시지 수 스트림
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChatRoom(String userId) {
    return chatsCol.doc(userId).snapshots();
  }

  // ════════════════════════════════════════════════════════════════════════
  // COMMENTS (자유게시판 댓글)
  //
  // Firestore 구조:
  //   posts/{postId}/comments/{commentId}
  // ════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> commentsCol(String postId) =>
      postsCol.doc(postId).collection('comments');

  /// 댓글 작성 (삭제 불가)
  Future<String> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String authorNationality,
    required String content,
    String originalLanguage = 'ko',
  }) async {
    final ref = commentsCol(postId).doc();
    // 댓글 저장 (핵심 - 반드시 성공해야 함)
    await ref.set({
      'comment_id': ref.id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_nationality': authorNationality,
      'content': content,
      'original_language': originalLanguage,
      'translations': <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
    });
    // 게시글의 comment_count 증가 (실패해도 댓글 저장은 유지)
    try {
      await postsCol.doc(postId).update({
        'comment_count': FieldValue.increment(1),
      });
    } catch (_) {
      // comment_count 업데이트 실패는 무시 (댓글은 이미 저장됨)
    }
    return ref.id;
  }

  /// 댓글의 번역 결과 저장
  Future<void> updateCommentTranslations({
    required String postId,
    required String commentId,
    required Map<String, String> translations,
    required String originalLanguage,
  }) async {
    await commentsCol(postId).doc(commentId).update({
      'translations': translations,
      'original_language': originalLanguage,
    });
  }

  /// 댓글 실시간 스트림 (오래된 순)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamComments(String postId) {
    return commentsCol(postId)
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  /// 댓글 단건 조회
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final snap = await commentsCol(postId)
        .orderBy('created_at', descending: false)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      if (data['comment_id'] == null || (data['comment_id'] as String).isEmpty) {
        data['comment_id'] = d.id;
      }
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  // POST TRANSLATION
  // ════════════════════════════════════════════════════════════════════════

  /// 게시글 번역 결과를 Firestore에 저장 (런타임 번역 캐시)
  Future<void> updatePostTranslations({
    required String postId,
    required Map<String, Map<String, String>> translations,
    required String originalLanguage,
  }) async {
    try {
      await postsCol.doc(postId).update({
        'translations': translations.map(
          (lang, map) => MapEntry(lang, Map<String, String>.from(map)),
        ),
        'original_language': originalLanguage,
        'is_translated': true,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('updatePostTranslations error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ERROR WRAPPER
  // ════════════════════════════════════════════════════════════════════════

  Future<T?> safeCall<T>(Future<T> Function() fn, String context) async {
    try {
      return await fn();
    } catch (e) {
      if (kDebugMode) debugPrint('FirestoreService [$context] error: $e');
      return null;
    }
  }
}
