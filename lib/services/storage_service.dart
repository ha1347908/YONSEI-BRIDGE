import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// User-specific saved-posts storage.
///
/// Each user's bookmarks are stored under a separate Hive key so that
/// newly registered (or different) accounts never see each other's saved posts.
class StorageService extends ChangeNotifier {
  // Shared Hive boxes (opened once in main.dart)
  final Box _savedPostsBox = Hive.box('saved_posts');
  final Box _userDataBox = Hive.box('user_data');

  // ── Active user tracking ──────────────────────────────────────────────────
  String? _currentUserId;

  /// Call this right after login / on app start to scope saved posts correctly.
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  String get _userPrefix => _currentUserId != null ? 'user_${_currentUserId}_' : 'guest_';

  // ── Saved Posts (per-user) ────────────────────────────────────────────────

  /// Save a post for the currently logged-in user.
  Future<void> savePost(String postId, Map<String, dynamic> postData) async {
    await _savedPostsBox.put('${_userPrefix}$postId', postData);
    notifyListeners();
  }

  /// Remove a saved post for the currently logged-in user.
  Future<void> removeSavedPost(String postId) async {
    await _savedPostsBox.delete('${_userPrefix}$postId');
    notifyListeners();
  }

  /// Check whether a post is saved by the currently logged-in user.
  bool isPostSaved(String postId) {
    return _savedPostsBox.containsKey('${_userPrefix}$postId');
  }

  /// Return all posts saved by the currently logged-in user.
  List<Map<String, dynamic>> getAllSavedPosts() {
    final posts = <Map<String, dynamic>>[];
    for (final key in _savedPostsBox.keys) {
      if (key.toString().startsWith(_userPrefix)) {
        final post = _savedPostsBox.get(key);
        if (post is Map) {
          posts.add(Map<String, dynamic>.from(post));
        }
      }
    }
    return posts;
  }

  // ── Generic user-data helpers ─────────────────────────────────────────────

  Future<void> saveUserData(String key, dynamic value) async {
    await _userDataBox.put(key, value);
    notifyListeners();
  }

  dynamic getUserData(String key) {
    return _userDataBox.get(key);
  }

  Future<void> removeUserData(String key) async {
    await _userDataBox.delete(key);
    notifyListeners();
  }
}
