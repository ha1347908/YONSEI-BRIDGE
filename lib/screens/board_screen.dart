import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../models/post_model.dart';

export '../models/post_model.dart';

// BoardCategory - 게시판 카테고리 모델
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
  final FirestoreService _fs = FirestoreService();

  List<Post> _posts = [];
  bool _isLoading = true;

  // 현재 유저가 저장한 postId 집합 (Firestore에서 조회)
  Set<String> _savedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      // ✅ Bug 1 Fix: SharedPreferences(로컬) → Firestore(서버) 로드
      // board_type 매핑: category.id → Firestore 필드값
      final boardType = _toBoardType(widget.category.id);

      final rawPosts = await _fs.getPosts(boardType: boardType);

      final loadedPosts = rawPosts.map((d) {
        // Firestore Timestamp → DateTime 변환
        DateTime createdAt;
        final ts = d['created_at'];
        if (ts != null && ts.runtimeType.toString().contains('Timestamp')) {
          createdAt = (ts as dynamic).toDate() as DateTime;
        } else if (ts is String) {
          createdAt = DateTime.tryParse(ts) ?? DateTime.now();
        } else {
          createdAt = DateTime.now();
        }

        return Post(
          id: d['post_id'] as String? ?? '',
          title: d['title'] as String? ?? '',
          content: d['content'] as String? ?? '',
          author: d['author_name'] as String? ?? 'Unknown',
          authorId: d['author_id'] as String? ?? '',
          createdAt: createdAt,
          categoryId: widget.category.id,
          isAdminPost: _adminIds.contains(d['author_id']),
          imageUrls: (d['image_urls'] as List<dynamic>?)?.cast<String>(),
          originalTitle: d['original_title'] as String?,
          originalContent: d['original_content'] as String?,
          originalLanguage: d['original_language'] as String?,
          translations: _parseTranslations(d['translations']),
          isTranslated: d['is_translated'] as bool? ?? false,
        );
      }).toList();

      // 북마크 상태 Firestore 조회
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUserId;
      Set<String> savedIds = {};
      if (userId != null) {
        final savedList = await _fs.getSavedPosts(userId);
        savedIds = savedList
            .map((p) => (p['post_id'] ?? p['id'] ?? '') as String)
            .toSet();
      }

      setState(() {
        _posts = loadedPosts;
        _savedPostIds = savedIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// category.id → Firestore board_type 값 변환
  String _toBoardType(String categoryId) {
    switch (categoryId) {
      case 'free_board':
        return 'free';
      case 'info_board':
        return 'info';
      default:
        // 이미 'free' / 'info' 형태로 오는 경우도 처리
        return categoryId;
    }
  }

  static const _adminIds = {
    'welovejesus',
    'bridge_master_haram',
    'bridge_master_jose',
    'manage_yb2026',
  };

  static Map<String, Map<String, String>> _parseTranslations(dynamic raw) {
    final result = <String, Map<String, String>>{};
    if (raw is Map) {
      raw.forEach((lang, val) {
        if (val is Map) {
          result[lang.toString()] =
              val.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      });
    }
    return result;
  }

  /// 북마크 토글 — Firestore 기반
  Future<void> _toggleSave(Post post) async {
    final authService =
        Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;
    if (userId == null) return;

    final isSaved = _savedPostIds.contains(post.id);

    // UI 즉시 반영 (optimistic update)
    setState(() {
      if (isSaved) {
        _savedPostIds.remove(post.id);
      } else {
        _savedPostIds.add(post.id);
      }
    });

    try {
      if (isSaved) {
        await _fs.unsavePost(userId, post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bookmark removed.'),
                duration: Duration(seconds: 1)),
          );
        }
      } else {
        // post_id 필드를 명시적으로 추가하여 saved_posts에서 조회 가능하게 함
        final data = post.toMap()..['post_id'] = post.id;
        await _fs.savePost(userId, post.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Post saved.'),
                duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      // 실패 시 롤백
      setState(() {
        if (isSaved) {
          _savedPostIds.add(post.id);
        } else {
          _savedPostIds.remove(post.id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Text('아직 게시글이 없습니다',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final isSaved = _savedPostIds.contains(post.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostDetailScreen(post: post),
                            ),
                          );
                          if (result == true) _loadPosts();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (post.isAdminPost)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.category.color,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '관리자',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      post.title,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // ✅ Firestore 기반 북마크 버튼
                                  IconButton(
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: isSaved
                                          ? widget.category.color
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _toggleSave(post),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.content,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(post.author,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(_formatDate(post.createdAt),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
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
              label:
                  const Text('글쓰기', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  bool _shouldShowWriteButton(BuildContext context) {
    final authService =
        Provider.of<AuthService>(context, listen: false);
    if (authService.isAnyAdmin) return true;
    if (widget.category.id == 'free_board') return true;
    return false;
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
