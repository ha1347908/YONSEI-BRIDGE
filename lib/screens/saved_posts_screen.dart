import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final FirestoreService _fs = FirestoreService();

  List<Post> _savedPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedPosts());
  }

  /// Firestore에서 북마크 목록을 가져온 뒤,
  /// 원본 포스트의 is_deleted 여부를 실시간 조인하여 필터링합니다.
  Future<void> _loadSavedPosts() async {
    if (!mounted) return;
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUserId;
    if (userId == null) {
      setState(() {
        _error = '로그인이 필요합니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1) 북마크 서브컬렉션에서 저장된 postId 목록 조회
      final savedList = await _fs.getSavedPosts(userId);

      // 2) 각 포스트의 원본 doc을 조인하여 삭제 여부 검증
      final validated = <Post>[];
      for (final saved in savedList) {
        final postId = saved['post_id'] as String? ?? saved['id'] as String?;
        if (postId == null || postId.isEmpty) continue;

        try {
          final originDoc = await _fs.postsCol.doc(postId).get();

          if (!originDoc.exists) {
            // 원본 doc 자체가 없음 → 북마크만 정리하고 skip
            await _fs.unsavePost(userId, postId);
            continue;
          }

          final originData = originDoc.data()!;
          if (originData['is_deleted'] == true) {
            // soft-delete된 포스트 → 북마크 정리 후 skip
            await _fs.unsavePost(userId, postId);
            continue;
          }

          // 최신 원본 데이터로 Post 객체 생성
          // fromMap이 'id'|'post_id', 'author'|'author_name', 'created_at'|'createdAt' 모두 처리
          final postMap = {
            ...originData,
            'id': postId,
            'post_id': postId,
          };
          validated.add(Post.fromMap(postMap));
        } catch (_) {
          // 개별 포스트 로드 실패 시 건너뜀
          continue;
        }
      }

      // 최신순 정렬
      validated.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _savedPosts = validated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '저장된 게시물을 불러오지 못했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unsave(String postId) async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUserId;
    if (userId == null) return;

    try {
      await _fs.unsavePost(userId, postId);
      if (mounted) {
        setState(() {
          _savedPosts.removeWhere((p) => p.id == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('북마크가 해제되었습니다.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 해제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 게시물'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _loadSavedPosts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSavedPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_savedPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '저장된 게시물이 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '관심 게시물에 북마크를 눌러보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedPosts.length,
        itemBuilder: (context, index) {
          final post = _savedPosts[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post),
                  ),
                );
                // 상세 화면에서 북마크 해제했을 수 있으므로 새로고침
                _loadSavedPosts();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 상단: 제목 + 북마크 버튼 ──────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.isAdminPost) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0038A8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark,
                              color: Color(0xFF0038A8)),
                          tooltip: '북마크 해제',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              maxWidth: 32, maxHeight: 32),
                          onPressed: () => _unsave(post.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── 본문 미리보기 ───────────────────────────
                    Text(
                      post.content,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // ── 하단: 작성자 · 날짜 · 조회수 · 스크랩수 ──
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(post.author,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(_formatDate(post.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        const Spacer(),
                        // 조회수
                        Icon(Icons.visibility_outlined,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text('${post.viewCount}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        // 스크랩수
                        Icon(Icons.bookmark_border,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text('${post.saveCount}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    // UTC → 로컬 시간으로 변환
    final localDate = date.isUtc ? date.toLocal() : date;
    final diff = DateTime.now().difference(localDate);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
