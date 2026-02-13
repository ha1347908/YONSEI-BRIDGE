import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'resume_form_screen.dart';
import 'symptom_card_screen.dart';

class BoardScreen extends StatefulWidget {
  final BoardCategory category;

  const BoardScreen({super.key, required this.category});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  // Sample posts - in a real app, these would come from Firebase
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
        return Post(
          id: postData['post_id'] ?? '',
          title: postData['title'] ?? '',
          content: postData['content'] ?? '',
          author: postData['author_name'] ?? 'Unknown',
          authorId: postData['author_id'] ?? '',
          createdAt: DateTime.parse(postData['created_at'] ?? DateTime.now().toIso8601String()),
          categoryId: postData['category'] ?? widget.category.id,
          isAdminPost: postData['author_id'] == 'admin',
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.category.color,
        foregroundColor: Colors.white,
        title: Text(widget.category.title),
        actions: [
          if (widget.category.id == 'need_job')
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResumeFormScreen(),
                  ),
                );
              },
              tooltip: '이력서 작성하기',
            ),
          if (widget.category.id == 'hospital_info')
            IconButton(
              icon: const Icon(Icons.medical_information),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SymptomCardScreen(),
                  ),
                );
              },
              tooltip: '증상카드 작성하기',
            ),
        ],
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
                      
                      // Reload posts if deleted
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.category.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '관리자',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  color: isSaved
                                      ? widget.category.color
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  if (isSaved) {
                                    storageService.removeSavedPost(post.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('저장이 취소되었습니다'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else {
                                    storageService.savePost(
                                      post.id,
                                      post.toMap(),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('게시글이 저장되었습니다'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.content,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.author,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: widget.category.allowUserPost
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
                
                // Reload posts if a new post was created
                if (result == true) {
                  _loadPosts();
                }
              },
              backgroundColor: widget.category.color,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                '글쓰기',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
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
    );
  }
}
