import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService extends ChangeNotifier {
  final Box _savedPostsBox = Hive.box('saved_posts');
  final Box _userDataBox = Hive.box('user_data');

  // Save a post
  Future<void> savePost(String postId, Map<String, dynamic> postData) async {
    await _savedPostsBox.put(postId, postData);
    notifyListeners();
  }

  // Remove a saved post
  Future<void> removeSavedPost(String postId) async {
    await _savedPostsBox.delete(postId);
    notifyListeners();
  }

  // Check if a post is saved
  bool isPostSaved(String postId) {
    return _savedPostsBox.containsKey(postId);
  }

  // Get all saved posts
  List<Map<String, dynamic>> getAllSavedPosts() {
    final posts = <Map<String, dynamic>>[];
    for (var key in _savedPostsBox.keys) {
      final post = _savedPostsBox.get(key);
      if (post is Map) {
        posts.add(Map<String, dynamic>.from(post));
      }
    }
    return posts;
  }

  // Save user data
  Future<void> saveUserData(String key, dynamic value) async {
    await _userDataBox.put(key, value);
    notifyListeners();
  }

  // Get user data
  dynamic getUserData(String key) {
    return _userDataBox.get(key);
  }

  // Remove user data
  Future<void> removeUserData(String key) async {
    await _userDataBox.delete(key);
    notifyListeners();
  }
}
