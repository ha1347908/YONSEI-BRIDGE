import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/language_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class SimpleChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;

  const SimpleChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  late Box _chatBox;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // Open or create chat box for this conversation
    final chatId = _getChatId(widget.currentUserId, widget.otherUserId);
    _chatBox = await Hive.openBox('chat_$chatId');
    _loadMessages();
  }

  String _getChatId(String userId1, String userId2) {
    // Create consistent chat ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  void _loadMessages() {
    final messagesData = _chatBox.get('messages', defaultValue: <dynamic>[]) as List;
    setState(() {
      _messages = messagesData
          .map((data) => ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      receiverId: widget.otherUserId,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    // Save to local storage
    await _chatBox.put(
      'messages',
      _messages.map((m) => m.toJson()).toList(),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6B4EFF),
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chat history is stored locally on your device only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == widget.currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0038A8),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0038A8) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
