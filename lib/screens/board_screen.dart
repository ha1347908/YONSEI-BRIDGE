import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../models/post_model.dart';

export '../models/post_model.dart';

// BoardCategory - 게시판 카테고리 모델 (하위 호환용)
class BoardCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool allowUserPost;

  BoardCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.allowUserPost,
  });
}

class BoardScreen extends StatefulWidget {
  final BoardCategory category;

  const BoardScreen({super.key, required this.category});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsKey = 'posts_${widget.category.id}';
      final postsJson = prefs.getString(postsKey) ?? '[]';
      final List<dynamic> postsList = jsonDecode(postsJson);
      
      final loadedPosts = postsList.map((postData) {
        List<String>? imageUrls;
        if (postData['images'] != null && postData['images'] is List && (postData['images'] as List).isNotEmpty) {
          imageUrls = (postData['images'] as List).map((base64String) {
            return base64String as String;
          }).toList();
        }
        
        return Post(
          id: postData['post_id'] ?? '',
          title: postData['title'] ?? '',
          content: postData['content'] ?? '',
          author: postData['author_name'] ?? 'Unknown',
          authorId: postData['author_id'] ?? '',
          createdAt: DateTime.parse(postData['created_at'] ?? DateTime.now().toIso8601String()),
          categoryId: postData['category'] ?? widget.category.id,
          isAdminPost: postData['author_id'] == 'welovejesus',
          imageUrls: imageUrls,
        );
      }).toList();
      
      setState(() {
        _posts = loadedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.category.color,
        foregroundColor: Colors.white,
        title: Text(widget.category.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '아직 게시글이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                final isSaved = storageService.isPostSaved(post.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: post),
                        ),
                      );
                      if (result == true) {
                        _loadPosts();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (post.isAdminPost)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.category.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '관리자',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  color: isSaved ? widget.category.color : Colors.grey,
                                ),
                                onPressed: () {
                                  if (isSaved) {
                                    storageService.removeSavedPost(post.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('저장이 취소되었습니다'), duration: Duration(seconds: 1)),
                                    );
                                  } else {
                                    storageService.savePost(post.id, post.toMap());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('게시글이 저장되었습니다'), duration: Duration(seconds: 1)),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(post.author, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(_formatDate(post.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _shouldShowWriteButton(context)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(
                      categoryId: widget.category.id,
                      categoryTitle: widget.category.title,
                    ),
                  ),
                );
                if (result == true) _loadPosts();
              },
              backgroundColor: widget.category.color,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('글쓰기', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  bool _shouldShowWriteButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAnyAdmin) return true;
    if (widget.category.id == 'free_board') return true;
    return false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
