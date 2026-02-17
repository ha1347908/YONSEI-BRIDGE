import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'board_screen.dart';
import 'simple_chat_screen.dart';

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

  Future<void> _showAuthorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    final currentUserName = prefs.getString('nickname') ?? 'User';

    // Get author info
    final authorId = widget.post.authorId;
    final authorName = widget.post.author;
    final authorNationality = prefs.getString('demo_nationality_$authorId') ?? 'Unknown';
    final authorContact = prefs.getString('demo_contact_$authorId') ?? 'Not provided';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              // Profile picture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0038A8).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF0038A8),
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Author name
              Text(
                authorName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Info cards
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 20, color: Color(0xFF0038A8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nationality',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authorNationality,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('닫기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0038A8)),
                        foregroundColor: const Color(0xFF0038A8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Navigate to chat with this user
                        if (currentUserId != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SimpleChatScreen(
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                otherUserId: authorId,
                                otherUserName: authorName,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('메시지'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final authService = Provider.of<AuthService>(context);
    final isSaved = storageService.isPostSaved(widget.post.id);
    
    // Check if current user can delete this post
    final currentUserId = authService.currentUserId;
    final isAdmin = currentUserId == 'welovejesus';
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
                  InkWell(
                    onTap: widget.post.isAdminPost ? null : _showAuthorProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.post.author,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: widget.post.isAdminPost ? Colors.black87 : const Color(0xFF0038A8),
                            decoration: widget.post.isAdminPost ? null : TextDecoration.underline,
                          ),
                        ),
                      ],
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
                          (base64String) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(base64String),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 48),
                                          SizedBox(height: 8),
                                          Text('이미지 로드 실패'),
                                        ],
                                      ),
                                    ),
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
