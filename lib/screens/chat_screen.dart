import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// 1:1 채팅 화면
/// - 일반 사용자: 관리자(welovejesus)와 채팅
/// - 관리자: [targetUserId] 로 지정된 특정 사용자와 채팅
class ChatScreen extends StatefulWidget {
  /// 관리자가 특정 사용자의 채팅방을 열 때 사용
  /// null 이면 현재 로그인한 사용자 자신의 채팅방을 엽니다.
  final String? targetUserId;
  final String? targetUserName;

  const ChatScreen({super.key, this.targetUserId, this.targetUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _chatRoomUserId; // chats/{userId} 의 userId
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    // welovejesus 뿐만 아니라 모든 관리자 계정(isAnyAdmin) 이 관리자로 동작
    _isAdmin = auth.isAnyAdmin;

    // 채팅방 ID = 항상 일반 사용자의 userId
    // 관리자가 targetUserId 를 지정해서 들어온 경우 그 ID를 채팅방으로 사용
    if (_isAdmin && widget.targetUserId != null) {
      _chatRoomUserId = widget.targetUserId!;
    } else if (_isAdmin) {
      // 관리자가 targetUserId 없이 진입한 경우 → 목록 화면으로 안내
      _chatRoomUserId = '';
    } else {
      _chatRoomUserId = auth.currentUserId ?? '';
    }

    // 화면 진입 시 읽음 처리
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    if (_chatRoomUserId.isEmpty) return;
    if (_isAdmin) {
      _fs.markReadByAdmin(_chatRoomUserId);
    } else {
      _fs.markReadByUser(_chatRoomUserId);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _chatRoomUserId.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    _inputController.clear();

    await _fs.sendMessage(
      userId:     _chatRoomUserId,
      userName:   _isAdmin
          ? (widget.targetUserName ?? _chatRoomUserId)
          : (auth.currentUserName ?? _chatRoomUserId),
      senderId:   auth.currentUserId ?? '',
      senderName: auth.currentUserName ?? '',
      senderRole: _isAdmin ? 'admin' : 'user',
      text:       text,
    );

    // 전송 후 스크롤 맨 아래로
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    // AppBar 제목: 관리자면 상대방 이름, 사용자면 "관리자와 채팅"
    final appBarTitle = _isAdmin
        ? (widget.targetUserName ?? _chatRoomUserId)
        : '관리자와 채팅하기';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appBarTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _isAdmin ? '사용자와 대화 중' : 'System Administrator',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── 안내 배너 ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0038A8).withValues(alpha: 0.07),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF0038A8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isAdmin
                        ? '사용자에게 답변을 보내고 있습니다.'
                        : '관리자가 확인 후 답변 드립니다. 운영 시간: 평일 09:00~18:00',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0038A8)),
                  ),
                ),
              ],
            ),
          ),

          // ── 메시지 목록 ────────────────────────────────────────────────
          Expanded(
            child: _chatRoomUserId.isEmpty
                ? const Center(child: Text('채팅 정보를 불러올 수 없습니다.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _fs.streamMessages(_chatRoomUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('오류: ${snapshot.error}'));
                      }

                      final docs = snapshot.data?.docs ?? [];

                      // 새 메시지 도착 시 읽음 처리
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markRead();
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _isAdmin
                                    ? '아직 메시지가 없습니다.'
                                    : '관리자에게 첫 메시지를 보내보세요!',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final isMe = data['sender_id'] == auth.currentUserId;
                          final isAdminMsg = data['sender_role'] == 'admin';
                          final text = data['text'] as String? ?? '';
                          final ts = data['created_at'];
                          final time = ts is Timestamp
                              ? _formatTime(ts.toDate())
                              : '';

                          return _MessageBubble(
                            text: text,
                            time: time,
                            isMe: isMe,
                            isAdmin: isAdminMsg,
                            senderName: data['sender_name'] as String? ?? '',
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── 입력창 ─────────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF0038A8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}

// ── 메시지 말풍선 위젯 ─────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isAdmin;
  final String senderName;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isAdmin,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대방 아바타 (내 메시지면 숨김)
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdmin
                  ? const Color(0xFF0038A8)
                  : const Color(0xFF6B4EFF).withValues(alpha: 0.2),
              child: isAdmin
                  ? const Icon(Icons.admin_panel_settings,
                      size: 16, color: Colors.white)
                  : Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4EFF)),
                    ),
            ),
            const SizedBox(width: 8),
          ],

          // 말풍선
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 발신자 이름 (상대방 메시지일 때만)
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      isAdmin ? '관리자' : senderName,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 시간 (내 메시지는 말풍선 왼쪽)
                    if (isMe) ...[
                      Text(time,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400)),
                      const SizedBox(width: 4),
                    ],
                    // 말풍선 본체
                    Container(
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.65),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF0038A8)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // 시간 (상대방 메시지는 말풍선 오른쪽)
                    if (!isMe) ...[
                      const SizedBox(width: 4),
                      Text(time,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
