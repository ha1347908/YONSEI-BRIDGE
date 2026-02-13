import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'board_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final postsKey = 'posts_${widget.post.categoryId}';
        final postsJson = prefs.getString(postsKey) ?? '[]';
        final List<dynamic> postsList = jsonDecode(postsJson);
        
        // Remove the post
        postsList.removeWhere((p) => p['post_id'] == widget.post.id);
        
        // Save back
        await prefs.setString(postsKey, jsonEncode(postsList));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('게시글 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final authService = Provider.of<AuthService>(context);
    final isSaved = storageService.isPostSaved(widget.post.id);
    
    // Check if current user can delete this post
    final currentUserId = authService.currentUserId;
    final isAdmin = currentUserId == 'admin';
    final isAuthor = currentUserId == widget.post.authorId;
    final canDelete = isAdmin || isAuthor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
              tooltip: '삭제',
            ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () {
              if (isSaved) {
                storageService.removeSavedPost(widget.post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장이 취소되었습니다')),
                );
              } else {
                storageService.savePost(widget.post.id, widget.post.toMap());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('게시글이 저장되었습니다')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Author and date
              Row(
                children: [
                  if (widget.post.isAdminPost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0038A8),
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.post.author,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Content
              Text(
                widget.post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              
              // Images (if any)
              if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: widget.post.imageUrls!
                        .map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
