import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/post_translation_provider.dart';
import '../models/post_model.dart';
import 'board_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    // PostTranslationProvider를 이 화면 스코프 내에서만 생성
    return ChangeNotifierProvider(
      create: (_) => PostTranslationProvider(post, lang.currentLanguage),
      child: _PostDetailBody(post: post),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PostDetailBody extends StatefulWidget {
  final Post post;
  const _PostDetailBody({required this.post});

  @override
  State<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<_PostDetailBody> {
  // ── 게시글 삭제 ────────────────────────────────────────────
  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'posts_${widget.post.categoryId}';
        final list =
            jsonDecode(prefs.getString(key) ?? '[]') as List<dynamic>;
        list.removeWhere((p) => p['post_id'] == widget.post.id);
        await prefs.setString(key, jsonEncode(list));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('게시글이 삭제되었습니다'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  // ── 작성자 프로필 ─────────────────────────────────────────
  Future<void> _showAuthorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final authorId = widget.post.authorId;
    final authorName = widget.post.author;
    final nationality =
        prefs.getString('demo_nationality_$authorId') ?? 'Unknown';
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF0038A8),
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(authorName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)),
                child: Row(
                  children: [
                    const Icon(Icons.flag,
                        size: 20, color: Color(0xFF0038A8)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nationality',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text(nationality,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('닫기'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0038A8),
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final authService = Provider.of<AuthService>(context);
    final translator = Provider.of<PostTranslationProvider>(context);
    final lang = Provider.of<LanguageService>(context);

    final isSaved = storageService.isPostSaved(widget.post.id);
    final isAdmin = authService.currentUserId == 'welovejesus';
    final isAuthor = authService.currentUserId == widget.post.authorId;
    final canDelete = isAdmin || isAuthor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          if (canDelete)
            IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deletePost,
                tooltip: '삭제'),
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              if (isSaved) {
                storageService.removeSavedPost(widget.post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('저장이 취소되었습니다')));
              } else {
                storageService.savePost(
                    widget.post.id, widget.post.toMap());
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 저장되었습니다')));
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 번역 중 인디케이터 ─────────────────────────
              if (translator.isTranslating)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.translate('translating'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),

              // ── 제목 ──────────────────────────────────────
              Text(
                translator.displayTitle,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── 작성자 / 날짜 / 배지 행 ──────────────────
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (widget.post.isAdminPost)
                    _badge('공식', const Color(0xFF0038A8), Colors.white),
                  if (widget.post.infoCategory != null)
                    _outlineBadge(
                      widget.post.infoCategory!.label,
                      _infoCategoryColor(widget.post.infoCategory!),
                    ),
                  // 원문 언어 배지 (번역된 경우)
                  if (translator.canToggle)
                    _outlineBadge(
                      translator.originalLanguageName,
                      Colors.orange[700]!,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  InkWell(
                    onTap: widget.post.isAdminPost ? null : _showAuthorProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, size: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.post.author,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: widget.post.isAdminPost
                                ? Colors.black87
                                : const Color(0xFF0038A8),
                            decoration: widget.post.isAdminPost
                                ? null
                                : TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.post.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(height: 28),

              // ── 본문 ──────────────────────────────────────
              Text(
                translator.displayContent,
                style: const TextStyle(fontSize: 16, height: 1.7),
              ),

              // ── 원문/번역 토글 버튼 ───────────────────────
              if (translator.canToggle) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TranslateToggleButton(translator: translator),
                ),
              ],

              // ── 이미지 ────────────────────────────────────
              if (widget.post.imageUrls != null &&
                  widget.post.imageUrls!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: widget.post.imageUrls!
                        .map((b64) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(b64),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 160,
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 40)),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── 헬퍼 ─────────────────────────────────────────────────
  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _outlineBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _infoCategoryColor(InfoCategory cat) {
    switch (cat) {
      case InfoCategory.mireaCampus:
        return const Color(0xFF0038A8);
      case InfoCategory.wonju:
        return const Color(0xFF00897B);
      case InfoCategory.korea:
        return const Color(0xFFE53935);
    }
  }
}

// ──────────────────────────────────────────────────────────────
// 번역 토글 버튼 위젯
// ──────────────────────────────────────────────────────────────
class _TranslateToggleButton extends StatelessWidget {
  final PostTranslationProvider translator;
  const _TranslateToggleButton({required this.translator});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final label = lang.translate(translator.toggleLabel);

    return GestureDetector(
      onTap: translator.toggleView,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF6B4EFF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF6B4EFF).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              translator.showOriginal
                  ? Icons.translate
                  : Icons.article_outlined,
              size: 14,
              color: const Color(0xFF6B4EFF),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B4EFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
