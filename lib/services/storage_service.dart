import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// User-specific storage service.
///
/// ⚠️ NOTE (Bug 3 fix): Bookmark(saved-posts) logic has been REMOVED from
/// this class and migrated to FirestoreService (cloud-synced).
/// Hive is now used only for generic user-data key-value pairs.
class StorageService extends ChangeNotifier {
  final Box _userDataBox = Hive.box('user_data');

  // ── Active user tracking ──────────────────────────────────────────────────
  String? _currentUserId;

  /// Call this right after login / on app start to scope data correctly.
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  String? get currentUserId => _currentUserId;

  // ── BOOKMARK METHODS REMOVED ──────────────────────────────────────────────
  // Previously: savePost / removeSavedPost / isPostSaved / getAllSavedPosts
  // were stored in Hive 'saved_posts' box, causing:
  //   - BUG 3a: deleted posts still visible (no Firestore validation)
  //   - BUG 3b: bookmarks not synced across devices
  //
  // All bookmark operations now go through FirestoreService:
  //   FirestoreService().savePost(userId, postId, postData)
  //   FirestoreService().unsavePost(userId, postId)
  //   FirestoreService().isPostSaved(userId, postId)
  //   FirestoreService().getSavedPosts(userId)
  // ─────────────────────────────────────────────────────────────────────────

  // ── Generic user-data helpers (non-bookmark) ──────────────────────────────

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
