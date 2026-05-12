import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

/// 관리자 전용 — 사용자 선택 후 개별 메시지 발송 화면
class AdminSendMessageScreen extends StatefulWidget {
  const AdminSendMessageScreen({super.key});

  @override
  State<AdminSendMessageScreen> createState() =>
      _AdminSendMessageScreenState();
}

class _AdminSendMessageScreenState extends State<AdminSendMessageScreen> {
  final FirestoreService _fs = FirestoreService();

  List<Map<String, dynamic>> _users = [];
  Set<String> _selectedUids = {};
  bool _isLoading = true;
  bool _isSending = false;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _fs.getApprovedUsers();
      // 관리자 계정 제외
      final filtered = users.where((u) {
        final uid = u['uid'] as String? ?? '';
        return !['welovejesus', 'bridge_master_haram', 'bridge_master_jose']
            .contains(uid);
      }).toList();
      // 닉네임 순 정렬
      filtered.sort((a, b) {
        final na = (a['nickname'] ?? a['name'] ?? '') as String;
        final nb = (b['nickname'] ?? b['name'] ?? '') as String;
        return na.compareTo(nb);
      });
      if (mounted) {
        setState(() {
          _users = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    if (_selectedUids.length == _users.length) {
      setState(() => _selectedUids.clear());
    } else {
      setState(() {
        _selectedUids = _users
            .map((u) => (u['uid'] ?? '') as String)
            .where((id) => id.isNotEmpty)
            .toSet();
      });
    }
  }

  void _toggleUser(String uid) {
    setState(() {
      if (_selectedUids.contains(uid)) {
        _selectedUids.remove(uid);
      } else {
        _selectedUids.add(uid);
      }
    });
  }

  Future<void> _sendMessages() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지를 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수신자를 선택해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUserId ?? 'welovejesus';
    final adminName = authService.currentUserName ?? '관리자';

    setState(() => _isSending = true);

    int successCount = 0;
    int failCount = 0;

    for (final uid in _selectedUids) {
      try {
        final userDoc = _users.firstWhere(
          (u) => (u['uid'] ?? '') == uid,
          orElse: () => {},
        );
        final userName =
            (userDoc['nickname'] ?? userDoc['name'] ?? 'Unknown') as String;

        await _fs.sendMessage(
          userId: uid,
          userName: userName,
          senderId: adminId,
          senderName: adminName,
          senderRole: 'admin',
          text: text,
        );
        successCount++;
      } catch (_) {
        failCount++;
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
      _messageController.clear();
      setState(() => _selectedUids.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? '${successCount}명에게 메시지를 보냈습니다'
                : '${successCount}명 성공, ${failCount}명 실패',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _users.isNotEmpty && _selectedUids.length == _users.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: const Text(
          '개별 메시지 발송',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── 메시지 입력 ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '발송할 메시지',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0038A8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '메시지를 입력하세요...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF0038A8), width: 1.5),
                          ),
                        ),
                        maxLines: 3,
                        minLines: 2,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── 전체선택 + 수신자 수 ─────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '수신자 선택 (${_selectedUids.length}/${_users.length}명)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _toggleSelectAll,
                        icon: Icon(
                          allSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: const Color(0xFF0038A8),
                          size: 20,
                        ),
                        label: Text(
                          allSelected ? '전체 해제' : '전체 선택',
                          style: const TextStyle(
                            color: Color(0xFF0038A8),
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── 사용자 목록 ─────────────────────────────
                Expanded(
                  child: _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                '승인된 사용자가 없습니다',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final uid =
                                (user['uid'] ?? '') as String;
                            final nickname =
                                (user['nickname'] ?? user['name'] ?? 'Unknown')
                                    as String;
                            final nationality =
                                (user['nationality'] ?? '') as String;
                            final isSelected = _selectedUids.contains(uid);

                            return InkWell(
                              onTap: () => _toggleUser(uid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0038A8)
                                          .withValues(alpha: 0.07)
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade100),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // 체크박스
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? const Color(0xFF0038A8)
                                          : Colors.grey.shade400,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    // 아바타
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF0038A8)
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        nickname.isNotEmpty
                                            ? nickname[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Color(0xFF0038A8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nickname,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFF0038A8)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (nationality.isNotEmpty)
                                            Text(
                                              nationality,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // 채팅 바로가기 버튼
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline,
                                          size: 20),
                                      color: Colors.grey.shade400,
                                      tooltip: '채팅 열기',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              targetUserId: uid,
                                              targetUserName: nickname,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // ── 발송 버튼 ────────────────────────────────
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isSending || _selectedUids.isEmpty)
                            ? null
                            : _sendMessages,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSending
                              ? '발송 중...'
                              : '${_selectedUids.length}명에게 메시지 발송',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0038A8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
