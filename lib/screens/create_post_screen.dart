import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  /// 정보게시판에서 FAB 눌렀을 때 현재 탭의 카테고리를 기본값으로 전달
  final InfoCategory? defaultInfoCategory;

  const CreatePostScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    this.defaultInfoCategory,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<XFile> _images = [];
  bool _isLoading = false;

  // 정보게시판 서브 카테고리 선택값
  InfoCategory? _selectedInfoCategory;

  // 정보게시판 여부
  bool get _isInfoBoard => widget.categoryId == 'info_board';

  static const List<InfoCategory> _infoCategoryOptions = [
    InfoCategory.mireaCampus,
    InfoCategory.wonju,
    InfoCategory.korea,
  ];

  @override
  void initState() {
    super.initState();
    // 기본 카테고리 설정 (탭에서 넘어온 값 or 첫 번째)
    _selectedInfoCategory =
        widget.defaultInfoCategory ?? InfoCategory.mireaCampus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    try {
      final images = await picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 50,
      );
      if (images.isNotEmpty) {
        setState(() => _images.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId ?? 'unknown';
      final userName = authService.currentUserName ?? 'Unknown User';

      // 이미지 base64 변환
      final List<String> imageBase64List = [];
      for (final img in _images) {
        try {
          imageBase64List.add(base64Encode(await img.readAsBytes()));
        } catch (_) {}
      }

      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';
      final postData = {
        'post_id': postId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': widget.categoryId,
        // 정보게시판 서브 카테고리 저장
        'info_category':
            _isInfoBoard ? _selectedInfoCategory?.id : null,
        'author_id': userId,
        'author_name': userName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'view_count': 0,
        'like_count': 0,
        'comment_count': 0,
        'is_notice': false,
        'is_deleted': false,
        'images': imageBase64List,
        'tags': [],
      };

      final prefs = await SharedPreferences.getInstance();
      final postsKey = 'posts_${widget.categoryId}';
      final existing =
          jsonDecode(prefs.getString(postsKey) ?? '[]') as List<dynamic>;
      existing.insert(0, postData);
      await prefs.setString(postsKey, jsonEncode(existing));

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '게시글이 등록되었습니다'
              '${imageBase64List.isNotEmpty ? ' (사진 ${imageBase64List.length}장 포함)' : ''}'
              '${_isInfoBoard && _selectedInfoCategory != null ? ' [${_selectedInfoCategory!.label}]' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('게시글 등록 실패: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── 카테고리 선택 색상 ─────────────────────────────────────
  Color _categoryColor(InfoCategory cat) {
    switch (cat) {
      case InfoCategory.mireaCampus:
        return const Color(0xFF0038A8);
      case InfoCategory.wonju:
        return const Color(0xFF00897B);
      case InfoCategory.korea:
        return const Color(0xFFE53935);
    }
  }

  IconData _categoryIcon(InfoCategory cat) {
    switch (cat) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryTitle} - 글쓰기'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: const Text(
              '등록',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 정보게시판 카테고리 선택 (관리자 전용) ───────────
                if (_isInfoBoard) ...[
                  const Text(
                    '게시 카테고리',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _infoCategoryOptions.map((cat) {
                      final selected = _selectedInfoCategory == cat;
                      final color = _categoryColor(cat);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedInfoCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color
                                  : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : color.withValues(alpha: 0.3),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(cat),
                                  color: selected ? Colors.white : color,
                                  size: 22,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        selected ? Colors.white : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                ],

                // ── 제목 ──────────────────────────────────────────
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '제목을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // ── 내용 ──────────────────────────────────────────
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '내용을 입력하세요',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 15,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '내용을 입력해주세요' : null,
                  maxLength: 5000,
                ),
                const SizedBox(height: 16),

                // ── 이미지 첨부 ───────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(
                    _images.isEmpty
                        ? '사진 추가 (최대 10장)'
                        : '사진 ${_images.length}장 선택됨',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                // ── 이미지 미리보기 ───────────────────────────────
                if (_images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(image.path,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover)
                                  : Image.file(File(image.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _images.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 32),

                // ── 등록 버튼 ─────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('게시글 등록',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
