import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import 'simple_chat_screen.dart';

/// Chat conversation preview model
class ChatConversation {
  final String userId;
  final String userName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isAdmin;

  ChatConversation({
    required this.userId,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isAdmin = false,
  });
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _conversations = [];
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = prefs.getString('nickname') ?? 'User';

    // Load chat conversations from Hive
    final chatBox = await Hive.openBox('chat_messages');
    final conversations = <String, ChatConversation>{};

    // Admin conversation (always show at top)
    conversations['support_admin'] = ChatConversation(
      userId: 'support_admin',
      userName: 'YONSEI BRIDGE Support',
      lastMessage: _getLastMessageForUser('support_admin', chatBox),
      lastMessageTime: _getLastMessageTimeForUser('support_admin', chatBox),
      unreadCount: _getUnreadCountForUser('support_admin', chatBox),
      isAdmin: true,
    );

    // Get all other conversations
    final allKeys = chatBox.keys.toList();
    for (var key in allKeys) {
      final chatData = chatBox.get(key);
      if (chatData is Map) {
        final senderId = chatData['senderId'] as String?;
        final receiverId = chatData['receiverId'] as String?;
        
        String? otherUserId;
        if (senderId == _currentUserId && receiverId != 'support_admin') {
          otherUserId = receiverId;
        } else if (receiverId == _currentUserId && senderId != 'support_admin') {
          otherUserId = senderId;
        }

        if (otherUserId != null && !conversations.containsKey(otherUserId)) {
          conversations[otherUserId] = ChatConversation(
            userId: otherUserId,
            userName: chatData['senderName'] as String? ?? 'User',
            lastMessage: _getLastMessageForUser(otherUserId, chatBox),
            lastMessageTime: _getLastMessageTimeForUser(otherUserId, chatBox),
            unreadCount: _getUnreadCountForUser(otherUserId, chatBox),
          );
        }
      }
    }

    setState(() {
      _conversations = conversations.values.toList();
      // Sort: Admin first, then by last message time
      _conversations.sort((a, b) {
        if (a.isAdmin) return -1;
        if (b.isAdmin) return 1;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
    });
  }

  String? _getLastMessageForUser(String userId, Box chatBox) {
    final allKeys = chatBox.keys.toList();
    String? lastMessage;
    DateTime? lastTime;

    for (var key in allKeys) {
      final chatData = chatBox.get(key);
      if (chatData is Map) {
        final senderId = chatData['senderId'] as String?;
        final receiverId = chatData['receiverId'] as String?;
        final timestamp = chatData['timestamp'] as String?;

        if ((senderId == userId || receiverId == userId) &&
            (senderId == _currentUserId || receiverId == _currentUserId)) {
          if (timestamp != null) {
            final msgTime = DateTime.parse(timestamp);
            if (lastTime == null || msgTime.isAfter(lastTime)) {
              lastTime = msgTime;
              lastMessage = chatData['message'] as String?;
            }
          }
        }
      }
    }

    return lastMessage;
  }

  DateTime? _getLastMessageTimeForUser(String userId, Box chatBox) {
    final allKeys = chatBox.keys.toList();
    DateTime? lastTime;

    for (var key in allKeys) {
      final chatData = chatBox.get(key);
      if (chatData is Map) {
        final senderId = chatData['senderId'] as String?;
        final receiverId = chatData['receiverId'] as String?;
        final timestamp = chatData['timestamp'] as String?;

        if ((senderId == userId || receiverId == userId) &&
            (senderId == _currentUserId || receiverId == _currentUserId)) {
          if (timestamp != null) {
            final msgTime = DateTime.parse(timestamp);
            if (lastTime == null || msgTime.isAfter(lastTime)) {
              lastTime = msgTime;
            }
          }
        }
      }
    }

    return lastTime;
  }

  int _getUnreadCountForUser(String userId, Box chatBox) {
    // TODO: Implement unread count logic
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('chat')),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with YONSEI BRIDGE Support',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _buildConversationTile(conversation);
                },
              ),
            ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: conversation.isAdmin
                ? const Color(0xFF6B4EFF)
                : const Color(0xFF0038A8),
            child: Icon(
              conversation.isAdmin ? Icons.support_agent : Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (conversation.isAdmin)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.userName,
              style: TextStyle(
                fontWeight: conversation.isAdmin ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Official',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ),
        ],
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            )
          : Text(
              'Start a conversation',
              style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF6B4EFF),
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () async {
        if (_currentUserId != null && _currentUserName != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimpleChatScreen(
                currentUserId: _currentUserId!,
                currentUserName: _currentUserName!,
                otherUserId: conversation.userId,
                otherUserName: conversation.userName,
              ),
            ),
          );
          // Reload conversations after returning from chat
          _loadConversations();
        }
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
