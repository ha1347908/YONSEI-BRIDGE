import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadSamplePosts();
  }

  void _loadSamplePosts() {
    // Sample data with unique IDs per category
    _posts.addAll([
      Post(
        id: '${widget.category.id}_1',
        title: '환영합니다! ${widget.category.title}입니다',
        content: '이곳은 ${widget.category.description}\n\n'
            '관리자가 게시한 공지사항과 정보를 확인하실 수 있습니다.',
        author: '관리자',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        categoryId: widget.category.id,
        isAdminPost: true,
      ),
      Post(
        id: '${widget.category.id}_2',
        title: '샘플 게시글 2',
        content: '이것은 샘플 게시글입니다.',
        author: '관리자',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        categoryId: widget.category.id,
        isAdminPost: true,
      ),
    ]);
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
      body: _posts.isEmpty
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: post),
                        ),
                      );
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(
                      categoryId: widget.category.id,
                      categoryTitle: widget.category.title,
                    ),
                  ),
                ).then((_) => setState(() {}));
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
  final DateTime createdAt;
  final String categoryId;
  final bool isAdminPost;
  final List<String>? imageUrls;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
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
      createdAt: DateTime.parse(map['createdAt'] as String),
      categoryId: map['categoryId'] as String,
      isAdminPost: map['isAdminPost'] as bool? ?? false,
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
