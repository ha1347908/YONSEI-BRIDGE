import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'board_screen.dart'; // Post re-export

// ──────────────────────────────────────────────────────────────
// 정보게시판 (탭 3개: IN MIREA CAMPUS / IN WONJU / IN KOREA)
// ──────────────────────────────────────────────────────────────
class InfoBoardScreen extends StatefulWidget {
  const InfoBoardScreen({super.key});

  @override
  State<InfoBoardScreen> createState() => _InfoBoardScreenState();
}

class _InfoBoardScreenState extends State<InfoBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _fs = FirestoreService();

  // 모든 정보글 로드 후 탭별로 필터링
  List<Post> _allPosts = [];
  bool _isLoading = true;
  Set<String> _savedPostIds = {};

  // 탭 순서 = InfoCategory 순서
  static const List<InfoCategory> _tabs = [
    InfoCategory.mireaCampus,
    InfoCategory.wonju,
    InfoCategory.korea,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // AuthService 초기화(checkLoginStatus) 완료 후 포스트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── 데이터 로드 ──────────────────────────────────────────────
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Bug 1 Fix: SharedPreferences → Firestore 로드
      final rawPosts = await _fs.getPosts(boardType: 'info');

      final loaded = rawPosts.map((d) {
        // Firestore Timestamp → DateTime
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
          categoryId: 'info_board',
          isAdminPost: true,
          imageUrls: (d['image_urls'] as List<dynamic>?)?.cast<String>(),
          infoCategory: InfoCategoryExt.fromId(d['info_category'] as String?),
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

      setState(() {
        _allPosts = loaded;
        _isLoading = false;
      });

      // 북마크 상태 Firestore 조회 (관리자 계정은 Firebase Auth 없어 saved_posts 접근 불가 → 건너뜀)
      final authSvc = Provider.of<AuthService>(context, listen: false);
      final userId = authSvc.currentUserId;
      if (userId != null && !authSvc.isAnyAdmin) {
        final savedList = await _fs.getSavedPosts(userId);
        final savedIds = savedList
            .map((p) => (p['post_id'] ?? p['id'] ?? '') as String)
            .toSet();
        if (mounted) setState(() => _savedPostIds = savedIds);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave(BuildContext context, Post post) async {
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
    } catch (_) {
      setState(() {
        if (isSaved) _savedPostIds.add(post.id);
        else _savedPostIds.remove(post.id);
      });
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

  // ── 탭 아이콘 ─────────────────────────────────────────
  IconData _tabIcon(InfoCategory cat) {
    switch (cat) {
      case InfoCategory.mireaCampus:
        return Icons.school_outlined;
      case InfoCategory.wonju:
        return Icons.location_city_outlined;
      case InfoCategory.korea:
        return Icons.flag_outlined;
    }
  }

  // ── 현재 탭 카테고리의 게시글만 필터 (고정글 먼저, 최신순) ──────────────────────────
  List<Post> _postsForCategory(InfoCategory cat) {
    final filtered = _allPosts.where((p) => p.infoCategory == cat).toList();
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
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
            Container(width: 1, height: 16, color: Colors.white38),
            const SizedBox(width: 8),
            Text(
              lang.translate('info_board'),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: const Color(0xFF0038A8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF0038A8),
              unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              tabs: _tabs.map((cat) {
                final icon = _tabIcon(cat);
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14),
                      const SizedBox(width: 4),
                      Text(cat.label, textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 설명 배너
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0038A8),
                  const Color(0xFF6B4EFF).withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Text(
              lang.translate('info_board_desc_full'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          // 탭 컨텐츠
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _tabs
                        .map((cat) => _InfoCategoryTab(
                              category: cat,
                              posts: _postsForCategory(cat),
                              onRefresh: _loadPosts,
                              savedPostIds: _savedPostIds,
                              onToggleSave: (post) => _toggleSave(context, post),
                              isAdmin: auth.isFullAdmin,
                              fs: _fs,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),

      // FAB: 관리자만 보임
      floatingActionButton: auth.isAnyAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                // 현재 탭의 카테고리를 기본 선택값으로 넘김
                final currentCat = _tabs[_tabController.index];
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(
                      categoryId: 'info_board',
                      categoryTitle: '정보 게시판',
                      defaultInfoCategory: currentCat,
                    ),
                  ),
                );
                if (result == true) _loadPosts();
              },
              backgroundColor: const Color(0xFF0038A8),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                lang.translate('write_post'),
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 탭 하나 = 카테고리 하나의 게시글 목록
// ──────────────────────────────────────────────────────────────
class _InfoCategoryTab extends StatelessWidget {
  final InfoCategory category;
  final List<Post> posts;
  final Future<void> Function() onRefresh;
  final Set<String> savedPostIds;
  final void Function(Post) onToggleSave;
  final bool isAdmin;
  final FirestoreService? fs;

  const _InfoCategoryTab({
    required this.category,
    required this.posts,
    required this.onRefresh,
    required this.savedPostIds,
    required this.onToggleSave,
    this.isAdmin = false,
    this.fs,
  });

  // 카테고리 별 테마 색상
  Color get _accentColor {
    switch (category) {
      case InfoCategory.mireaCampus:
        return const Color(0xFF0038A8);
      case InfoCategory.wonju:
        return const Color(0xFF00897B);
      case InfoCategory.korea:
        return const Color(0xFFE53935);
    }
  }

  IconData get _icon {
    switch (category) {
      case InfoCategory.mireaCampus:
        return Icons.school;
      case InfoCategory.wonju:
        return Icons.location_city;
      case InfoCategory.korea:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('no_posts'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final isSaved = savedPostIds.contains(post.id);
          return _PostCard(
            post: post,
            isSaved: isSaved,
            accentColor: _accentColor,
            lang: lang,
            onRefresh: onRefresh,
            onToggleSave: () => onToggleSave(post),
            isAdmin: isAdmin,
            fs: fs,
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 게시글 카드
// ──────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Post post;
  final bool isSaved;
  final Color accentColor;
  final LanguageService lang;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleSave;
  final bool isAdmin;
  final FirestoreService? fs;

  const _PostCard({
    required this.post,
    required this.isSaved,
    required this.accentColor,
    required this.lang,
    required this.onRefresh,
    required this.onToggleSave,
    this.isAdmin = false,
    this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: post.isPinned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: post.isPinned
            ? BorderSide(color: accentColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
          if (result == true) onRefresh();
        },
        onLongPress: isAdmin
            ? () => _showPinMenu(context)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 고정 배지 ──────────────────────────────
              if (post.isPinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 13, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '상단고정',
                        style: TextStyle(
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 공식 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '공식',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 카테고리 배지
                  if (post.infoCategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        post.infoCategory!.label,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // 관리자 핀 버튼
                  if (isAdmin)
                    IconButton(
                      constraints:
                          const BoxConstraints(maxWidth: 32, maxHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        post.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: post.isPinned
                            ? accentColor
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                      onPressed: () => _togglePin(context),
                      tooltip: post.isPinned ? '고정 해제' : '상단고정',
                    ),
                  // 북마크
                  GestureDetector(
                    onTap: onToggleSave,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? accentColor : Colors.grey,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              // ── 하단 통계 바 ────────────────────────────────
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
                  if (post.imageUrls != null &&
                      post.imageUrls!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.image_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      '${post.imageUrls!.length}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
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

  String _formatDate(DateTime date) {
    final localDate = date.isUtc ? date.toLocal() : date;
    final diff = DateTime.now().difference(localDate);
    if (diff.isNegative) return '방금 전';
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}년 전';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}달 전';
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    if (diff.inSeconds > 10) return '${diff.inSeconds}초 전';
    return '방금 전';
  }

  Future<void> _togglePin(BuildContext context) async {
    if (fs == null) return;
    try {
      await fs!.pinPost(post.id, !post.isPinned);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(post.isPinned ? '고정이 해제되었습니다.' : '상단에 고정되었습니다.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('고정 처리 실패: $e')),
        );
      }
    }
  }

  void _showPinMenu(BuildContext context) {
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
              title: Text(post.isPinned ? '상단고정 해제' : '상단에 고정'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
