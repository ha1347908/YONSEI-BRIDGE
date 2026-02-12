import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'board_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final isSaved = storageService.isPostSaved(post.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () {
              if (isSaved) {
                storageService.removeSavedPost(post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장이 취소되었습니다')),
                );
              } else {
                storageService.savePost(post.id, post.toMap());
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
                post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Author and date
              Row(
                children: [
                  if (post.isAdminPost)
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
                    post.author,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
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
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              
              // Images (if any)
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: post.imageUrls!
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
