import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

/// 관리자 전용 — 전체 사용자 채팅 목록 화면
/// welovejesus 계정으로만 진입 가능
class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: const Text(
          '사용자 채팅 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.streamAllChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '아직 채팅을 시작한 사용자가 없습니다.',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final userId   = data['user_id']   as String? ?? docs[index].id;
              final userName = data['user_name'] as String? ?? userId;
              final lastMsg  = data['last_message'] as String? ?? '';
              final unread   = (data['unread_by_admin'] as num?)?.toInt() ?? 0;

              // 마지막 메시지 시간
              final ts = data['last_message_at'];
              String timeStr = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                final now = DateTime.now();
                final diff = now.difference(dt);
                if (diff.inDays == 0) {
                  final h = dt.hour.toString().padLeft(2, '0');
                  final m = dt.minute.toString().padLeft(2, '0');
                  timeStr = '$h:$m';
                } else if (diff.inDays < 7) {
                  timeStr = '${diff.inDays}일 전';
                } else {
                  timeStr = '${dt.month}/${dt.day}';
                }
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4EFF),
                        ),
                      ),
                    ),
                    // 읽지 않은 메시지 뱃지
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                    fontWeight:
                        unread > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMsg.isEmpty ? '메시지 없음' : lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread > 0
                        ? Colors.black87
                        : Colors.grey.shade500,
                    fontWeight:
                        unread > 0 ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        targetUserId:   userId,
                        targetUserName: userName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
