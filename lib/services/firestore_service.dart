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
    Map<String, String> translations = const {},
    String originalLanguage = 'ko',
  }) async {
    final ref = postsCol.doc();
    await ref.set({
      'post_id': ref.id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'board_type': boardType,
      'info_category': infoCategory,
      'image_urls': imageUrls,
      'translations': translations,
      'original_language': originalLanguage,
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
    final posts = snap.docs.map((d) => d.data()).toList();
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
