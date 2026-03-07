import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'board_screen.dart'; // Post 클래스 re-export

class InfoBoardScreen extends StatefulWidget {
  const InfoBoardScreen({super.key});

  @override
  State<InfoBoardScreen> createState() => _InfoBoardScreenState();
}

class _InfoBoardScreenState extends State<InfoBoardScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('posts_info_board') ?? '[]';
      final List<dynamic> postsList = jsonDecode(postsJson);
      final loadedPosts = postsList.map((postData) {
        List<String>? imageUrls;
        if (postData['images'] != null && postData['images'] is List && (postData['images'] as List).isNotEmpty) {
          imageUrls = (postData['images'] as List).map((s) => s as String).toList();
        }
        return Post(
          id: postData['post_id'] ?? '',
          title: postData['title'] ?? '',
          content: postData['content'] ?? '',
          author: postData['author_name'] ?? 'Unknown',
          authorId: postData['author_id'] ?? '',
          createdAt: DateTime.parse(postData['created_at'] ?? DateTime.now().toIso8601String()),
          categoryId: 'info_board',
          isAdminPost: true,
          imageUrls: imageUrls,
        );
      }).toList();

      setState(() {
        _posts = loadedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);
    final storageService = Provider.of<StorageService>(context);

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
      ),
      body: Column(
        children: [
          // 설명 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0038A8),
                  const Color(0xFF6B4EFF).withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Text(
              lang.translate('info_board_desc_full'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined, size: 72, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              lang.translate('no_posts'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
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
                            final isSaved = storageService.isPostSaved(post.id);
                            return _buildPostCard(
                              context,
                              post,
                              isSaved,
                              storageService,
                              lang,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: authService.isAnyAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreatePostScreen(
                      categoryId: 'info_board',
                      categoryTitle: '정보 게시판',
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

  Widget _buildPostCard(
    BuildContext context,
    Post post,
    bool isSaved,
    StorageService storageService,
    LanguageService lang,
  ) {
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
          if (result == true) _loadPosts();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0038A8),
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
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? const Color(0xFF0038A8) : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () {
                      if (isSaved) {
                        storageService.removeSavedPost(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.translate('post_unsaved')), duration: const Duration(seconds: 1)),
                        );
                      } else {
                        storageService.savePost(post.id, post.toMap());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.translate('post_saved')), duration: const Duration(seconds: 1)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.content,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.image_outlined, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${post.imageUrls!.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}
