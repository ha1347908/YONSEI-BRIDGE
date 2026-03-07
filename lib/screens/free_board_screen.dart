import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'board_screen.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen> {
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
      final postsJson = prefs.getString('posts_free_board') ?? '[]';
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
          categoryId: 'free_board',
          isAdminPost: false,
          imageUrls: imageUrls,
        );
      }).toList();
      // 최신순 정렬
      loadedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
              lang.translate('free_board'),
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
            color: const Color(0xFF0038A8).withValues(alpha: 0.05),
            child: Text(
              lang.translate('free_board_desc_full'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                            Icon(Icons.forum_outlined, size: 72, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              lang.translate('no_posts'),
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lang.translate('be_first_to_write'),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
                              authService,
                            );
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
    StorageService storageService,
    LanguageService lang,
    AuthService authService,
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
                  // 작성자 아바타
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                    child: Text(
                      post.author.isNotEmpty ? post.author[0].toUpperCase() : '?',
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
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  if (authService.isAnyAdmin || authService.currentUserId == post.authorId)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        authService.isAnyAdmin ? '관리자' : '내 글',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
              const SizedBox(height: 10),
              Text(
                post.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                post.content,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '사진 ${post.imageUrls!.length}장',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
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
