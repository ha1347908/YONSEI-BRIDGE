import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/firestore_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'board_screen.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen> {
  final FirestoreService _fs = FirestoreService();

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _savedPostIds = {};

  @override
  void initState() {
    super.initState();
    // AuthService 초기화(checkLoginStatus) 완료 후 포스트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('[FreeBoardScreen] _loadPosts START');
      final rawPosts = await _fs.getPosts(boardType: 'free');
      debugPrint('[FreeBoardScreen] _loadPosts got ${rawPosts.length} posts');

      final loadedPosts = rawPosts.map((d) {
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
          categoryId: 'free_board',
          isAdminPost: false,
          isPinned: d['is_pinned'] as bool? ?? false,
          imageUrls: (d['image_urls'] as List<dynamic>?)?.cast<String>(),
          originalTitle: d['original_title'] as String?,
          originalContent: d['original_content'] as String?,
          originalLanguage: d['original_language'] as String?,
          translations: _parseTranslations(d['translations']),
          isTranslated: d['is_translated'] as bool? ?? false,
          viewCount: (d['view_count'] as num?)?.toInt() ?? 0,
          saveCount: (d['save_count'] as num?)?.toInt() ?? 0,
          commentCount: (d['comment_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      // ✅ 정렬: 고정글 먼저, 그 다음 최신순
      loadedPosts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      // 북마크 상태 조회 (관리자 계정은 Firebase Auth 없어 saved_posts 접근 불가 → 건너뜀)
      final authSvc = Provider.of<AuthService>(context, listen: false);
      final userId = authSvc.currentUserId;
      Set<String> savedIds = {};
      if (userId != null && !authSvc.isAnyAdmin) {
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
    } catch (e, stack) {
      debugPrint('[FreeBoardScreen] _loadPosts ERROR: $e');
      debugPrint('[FreeBoardScreen] Stack: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleSave(Post post) async {
    final authSvc = Provider.of<AuthService>(context, listen: false);
    // 관리자는 북마크 기능 사용 불가 (Firebase Auth 없음)
    if (authSvc.isAnyAdmin) return;
    final userId = authSvc.currentUserId;
    if (userId == null) return;
    final isSaved = _savedPostIds.contains(post.id);
    setState(() {
      if (isSaved) _savedPostIds.remove(post.id);
      else _savedPostIds.add(post.id);
    });
    try {
      if (isSaved) {
        await _fs.unsavePost(userId, post.id);
      } else {
        final data = post.toMap()..['post_id'] = post.id;
        await _fs.savePost(userId, post.id, data);
      }
    } catch (e) {
      setState(() {
        if (isSaved) _savedPostIds.add(post.id);
        else _savedPostIds.remove(post.id);
      });
    }
  }

  /// 게시글 고정/해제 (welovejesus 관리자만)
  Future<void> _togglePin(Post post, AuthService authService) async {
    if (!authService.isFullAdmin) return;
    try {
      await _fs.pinPost(post.id, !post.isPinned);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(post.isPinned ? '게시글 고정이 해제되었습니다' : '게시글이 고정되었습니다'),
            backgroundColor: const Color(0xFF0038A8),
          ),
        );
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'YONSEI BRIDGE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: Colors.white38,
            ),
            const SizedBox(width: 8),
            Text(
              lang.translate('free_board'),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0038A8).withValues(alpha: 0.05),
            child: Text(
              lang.translate('free_board_desc_full'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(
                                '게시글을 불러오지 못했습니다',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadPosts,
                                icon: const Icon(Icons.refresh),
                                label: const Text('다시 시도'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0038A8),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _posts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.forum_outlined,
                                    size: 72, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  lang.translate('no_posts'),
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lang.translate('be_first_to_write'),
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPosts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                final isSaved = _savedPostIds.contains(post.id);
                                return _buildPostCard(
                                    context, post, isSaved, lang, authService);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(
                categoryId: 'free_board',
                categoryTitle: '자유 게시판',
              ),
            ),
          );
          if (result == true) _loadPosts();
        },
        backgroundColor: const Color(0xFF0038A8),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(
          lang.translate('write_post'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    Post post,
    bool isSaved,
    LanguageService lang,
    AuthService authService,
  ) {
    final isPinned = post.isPinned;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isPinned ? 4 : 2,
      // 고정글은 테두리 강조
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPinned
            ? const BorderSide(color: Color(0xFF0038A8), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
          if (result == true) _loadPosts();
        },
        // 길게 누르면 관리자에게 고정 메뉴 표시
        onLongPress: authService.isFullAdmin
            ? () => _showPinMenu(context, post, authService)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 고정 배지 ────────────────────────────
              if (isPinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin,
                          size: 14, color: Color(0xFF0038A8)),
                      const SizedBox(width: 4),
                      Text(
                        '고정된 게시글',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0038A8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                    child: Text(
                      post.author.isNotEmpty
                          ? post.author[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4EFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B4EFF),
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  // 관리자: 고정 핀 버튼
                  if (authService.isFullAdmin)
                    IconButton(
                      constraints:
                          const BoxConstraints(maxWidth: 36, maxHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: isPinned
                            ? const Color(0xFF0038A8)
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () => _togglePin(post, authService),
                      tooltip: isPinned ? '고정 해제' : '게시글 고정',
                    ),
                  IconButton(
                    constraints:
                        const BoxConstraints(maxWidth: 36, maxHeight: 36),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color:
                          isSaved ? const Color(0xFF0038A8) : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => _toggleSave(post),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.titleFor(lang.currentLanguage),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                post.contentFor(lang.currentLanguage),
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.imageUrls != null &&
                  post.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.image_outlined,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '사진 ${post.imageUrls!.length}장',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
              // ── 하단 통계 바: 날짜·조회수·스크랩수·댓글수 ──
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const Spacer(),
                  Icon(Icons.visibility_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text('${post.viewCount}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Icon(Icons.bookmark_border,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text('${post.saveCount}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                  const SizedBox(width: 8),
                  Icon(Icons.chat_bubble_outline,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text('${post.commentCount}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinMenu(
      BuildContext context, Post post, AuthService authService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: const Color(0xFF0038A8),
              ),
              title: Text(post.isPinned ? '고정 해제' : '게시글 고정'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(post, authService);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Firestore Timestamp.toDate()는 로컬 DateTime 반환
    // UTC 플래그가 있으면 로컬로 변환
    final localDate = date.isUtc ? date.toLocal() : date;
    final now = DateTime.now();
    final diff = now.difference(localDate);
    // 미래 시간(서버/클라이언트 시간 오차)은 방금 전으로 처리
    if (diff.isNegative) return '방금 전';
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}년 전';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}달 전';
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    if (diff.inSeconds > 10) return '${diff.inSeconds}초 전';
    return '방금 전';
  }
}
