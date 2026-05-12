import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../services/post_translation_provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'board_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    // PostTranslationProvider를 이 화면 스코프 내에서만 생성
    return ChangeNotifierProvider(
      create: (_) => PostTranslationProvider(post, lang.currentLanguage, FirestoreService()),
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
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSaved = false;
  bool _isBookmarkLoading = false;
  bool _isSubmittingComment = false;

  /// 댓글 목록 (실시간 스트림 대신 상태로 관리)
  List<Comment> _comments = [];
  bool _commentsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSaveState();
      _loadComments();
      // 조회수 증가 (비동기, 결과 무시)
      _fs.incrementViewCount(widget.post.id).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Firestore에서 현재 유저의 북마크 여부를 조회
  Future<void> _loadSaveState() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUserId;
    if (userId == null) return;
    try {
      final saved = await _fs.isPostSaved(userId, widget.post.id);
      if (mounted) setState(() => _isSaved = saved);
    } catch (_) {}
  }

  /// Firestore에서 댓글 목록 로드
  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _commentsLoading = true);
    try {
      final docs = await _fs.getComments(widget.post.id);
      final comments = docs.map((d) => Comment.fromFirestore(d, d['comment_id'] ?? '')).toList();
      if (mounted) {
        setState(() {
          _comments = comments;
          _commentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  /// 댓글 등록
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (_isSubmittingComment) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final lang = Provider.of<LanguageService>(context, listen: false);
    final userId = authService.currentUserId;
    final userName = authService.currentUserName;
    if (userId == null || userName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ post.id 검증 - 빈 값이면 등록 불가
    final postId = widget.post.id;
    if (postId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글 ID를 불러오지 못했습니다. 화면을 닫고 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      // 작성자 국적 Firestore에서 조회
      String nationality = 'Unknown';
      try {
        final userData = await _fs.getUser(userId);
        nationality = userData?['nationality'] as String? ?? 'Unknown';
      } catch (_) {}

      // 원문 언어 감지 (실패해도 댓글 저장은 계속)
      String originalLang = 'ko';
      try {
        final detectedLang = await TranslationService.detectLanguage(text);
        originalLang = _normalizeDetectedLang(detectedLang);
      } catch (_) {
        // 언어 감지 실패 시 기본값 'ko' 사용
      }

      // Firestore에 댓글 저장
      final commentId = await _fs.addComment(
        postId: postId,
        authorId: userId,
        authorName: userName,
        authorNationality: nationality,
        content: text,
        originalLanguage: originalLang,
      );

      _commentController.clear();

      // 댓글 목록에 즉시 추가 (optimistic)
      final newComment = Comment(
        id: commentId,
        postId: postId,
        authorId: userId,
        authorName: userName,
        authorNationality: nationality,
        content: text,
        originalLanguage: originalLang,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _comments = [..._comments, newComment];
          _isSubmittingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.translate('comment_submitted')),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 백그라운드: 다른 언어로 번역 후 Firestore 업데이트
      _translateCommentInBackground(
        postId: postId,
        commentId: commentId,
        text: text,
        originalLang: originalLang,
      );

      // 스크롤을 맨 아래로
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        final lang2 = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang2.translate('comment_submit_failed')}: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 백그라운드에서 댓글 번역 후 Firestore 업데이트
  Future<void> _translateCommentInBackground({
    required String postId,
    required String commentId,
    required String text,
    required String originalLang,
  }) async {
    try {
      final targets = kSupportedLangs.where((l) => l != originalLang).toList();
      final Map<String, String> translations = {};

      await Future.wait(targets.map((lang) async {
        final translated = await TranslationService.translate(
          text: text,
          targetLang: lang,
          sourceLang: originalLang == 'unknown' ? 'auto' : originalLang,
        );
        translations[lang] = translated;
      }));

      // Firestore에 번역 저장
      await _fs.updateCommentTranslations(
        postId: postId,
        commentId: commentId,
        translations: translations,
        originalLanguage: originalLang,
      );

      // 로컬 상태도 업데이트
      if (mounted) {
        setState(() {
          _comments = _comments.map((c) {
            if (c.id == commentId) {
              return Comment(
                id: c.id,
                postId: c.postId,
                authorId: c.authorId,
                authorName: c.authorName,
                authorNationality: c.authorNationality,
                content: c.content,
                originalLanguage: originalLang,
                createdAt: c.createdAt,
                translations: translations,
              );
            }
            return c;
          }).toList();
        });
      }
    } catch (_) {}
  }

  String _normalizeDetectedLang(String code) {
    if (code.startsWith('zh')) return 'zh';
    if (code == 'unknown') return 'ko';
    return code;
  }

  /// 북마크 토글 — Firestore 기반
  Future<void> _toggleSave() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUserId;
    if (userId == null) return;
    if (_isBookmarkLoading) return;

    setState(() => _isBookmarkLoading = true);

    final wasSaved = _isSaved;
    setState(() => _isSaved = !_isSaved);

    try {
      if (wasSaved) {
        await _fs.unsavePost(userId, widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bookmark removed.')));
        }
      } else {
        final data = widget.post.toMap()..['post_id'] = widget.post.id;
        await _fs.savePost(userId, widget.post.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post saved.')));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSaved = wasSaved);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBookmarkLoading = false);
    }
  }

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
        await _fs.deletePost(widget.post.id);
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
    final authorId   = widget.post.authorId;
    final authorName = widget.post.author;
    String nationality = 'Unknown';
    try {
      final userData = await _fs.getUser(authorId);
      nationality = userData?['nationality'] as String? ?? 'Unknown';
    } catch (_) {}
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
    final authService = Provider.of<AuthService>(context);
    final translator = Provider.of<PostTranslationProvider>(context);
    final lang = Provider.of<LanguageService>(context);

    final isAuthor = authService.currentUserId == widget.post.authorId;
    final canDelete = authService.isAnyAdmin || isAuthor;

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
          _isBookmarkLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Colors.white : null,
                  ),
                  onPressed: _toggleSave,
                  tooltip: _isSaved ? 'Remove bookmark' : 'Save post',
                ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 스크롤 가능한 본문 + 댓글 영역 ──────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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

                    // ── 댓글 섹션 ─────────────────────────────────
                    const SizedBox(height: 24),
                    _buildCommentSection(lang, authService),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── 댓글 입력창 (하단 고정) ─────────────────────────
            _buildCommentInput(lang),
          ],
        ),
      ),
    );
  }

  // ── 댓글 섹션 빌더 ───────────────────────────────────────
  Widget _buildCommentSection(LanguageService lang, AuthService authService) {
    final currentLang = lang.currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 댓글 헤더
        Row(
          children: [
            const Icon(Icons.comment_outlined, size: 18, color: Color(0xFF0038A8)),
            const SizedBox(width: 6),
            Text(
              '${lang.translate('comments')} ${_comments.isNotEmpty ? '(${_comments.length})' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0038A8),
              ),
            ),
          ],
        ),
        const Divider(height: 16),

        if (_commentsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                lang.translate('no_comments'),
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return _CommentCard(
                comment: comment,
                currentLang: currentLang,
                lang: lang,
              );
            },
          ),
      ],
    );
  }

  // ── 댓글 입력창 ─────────────────────────────────────────
  Widget _buildCommentInput(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: lang.translate('write_comment'),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF0038A8), width: 1.5),
                ),
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          _isSubmittingComment
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0038A8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _submitComment,
                    tooltip: lang.translate('submit_comment'),
                  ),
                ),
        ],
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
// 댓글 카드 위젯 (번역 토글 포함)
// ──────────────────────────────────────────────────────────────
class _CommentCard extends StatefulWidget {
  final Comment comment;
  final String currentLang;
  final LanguageService lang;

  const _CommentCard({
    required this.comment,
    required this.currentLang,
    required this.lang,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final lang = widget.lang;
    final currentLang = widget.currentLang;

    // 번역 여부 확인 (현재 언어로 번역본이 있고 원문 언어와 다를 때)
    final hasTranslation = comment.hasTranslationFor(currentLang);
    final displayContent = (_showOriginal || !hasTranslation)
        ? comment.content
        : comment.contentFor(currentLang);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아바타
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0038A8).withValues(alpha: 0.15),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Color(0xFF0038A8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닉네임 + 국적 + 시간
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comment.authorNationality,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatRelativeTime(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 댓글 내용
                Text(
                  displayContent,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                // 번역 토글 버튼 (번역본이 있을 때만)
                if (hasTranslation) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _showOriginal = !_showOriginal),
                    child: Text(
                      _showOriginal
                          ? lang.translate('see_translated_comment')
                          : lang.translate('see_original_comment'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${date.month}/${date.day}';
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
