import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
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

  // 모든 정보글 로드 후 탭별로 필터링
  List<Post> _allPosts = [];
  bool _isLoading = true;

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
    _loadPosts();
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
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('posts_info_board') ?? '[]';
      final List<dynamic> raw = jsonDecode(postsJson);

      final loaded = raw.map((d) {
        List<String>? imgs;
        if (d['images'] is List && (d['images'] as List).isNotEmpty) {
          imgs = (d['images'] as List).cast<String>();
        }
        return Post(
          id: d['post_id'] ?? '',
          title: d['title'] ?? '',
          content: d['content'] ?? '',
          author: d['author_name'] ?? 'Unknown',
          authorId: d['author_id'] ?? '',
          createdAt: DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now(),
          categoryId: 'info_board',
          isAdminPost: true,
          imageUrls: imgs,
          infoCategory: InfoCategoryExt.fromId(d['info_category'] as String?),
        );
      }).toList();

      setState(() {
        _allPosts = loaded;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── 현재 탭 카테고리의 게시글만 필터 ──────────────────────────
  List<Post> _postsForCategory(InfoCategory cat) =>
      _allPosts.where((p) => p.infoCategory == cat).toList();

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
            Image.asset(
              'assets/images/yonsei_bridge_logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            Text(
              lang.translate('info_board'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          tabs: _tabs
              .map((cat) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ))
              .toList(),
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

  const _InfoCategoryTab({
    required this.category,
    required this.posts,
    required this.onRefresh,
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
    final storageService = Provider.of<StorageService>(context);
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
          final isSaved = storageService.isPostSaved(post.id);
          return _PostCard(
            post: post,
            isSaved: isSaved,
            accentColor: _accentColor,
            storageService: storageService,
            lang: lang,
            onRefresh: onRefresh,
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
  final StorageService storageService;
  final LanguageService lang;
  final Future<void> Function() onRefresh;

  const _PostCard({
    required this.post,
    required this.isSaved,
    required this.accentColor,
    required this.storageService,
    required this.lang,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
          if (result == true) onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  // 북마크
                  GestureDetector(
                    onTap: () {
                      if (isSaved) {
                        storageService.removeSavedPost(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(lang.translate('post_unsaved')),
                          duration: const Duration(seconds: 1),
                        ));
                      } else {
                        storageService.savePost(post.id, post.toMap());
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(lang.translate('post_saved')),
                          duration: const Duration(seconds: 1),
                        ));
                      }
                    },
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
                post.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                post.content,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                  if (post.imageUrls != null &&
                      post.imageUrls!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.image_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${post.imageUrls!.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
