import 'package:flutter/material.dart';

class ChatResponseTimeScreen extends StatelessWidget {
  final String period;
  
  const ChatResponseTimeScreen({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티 채팅 응답 속도'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Chat Response Time Screen - Coming Soon'),
      ),
    );
  }
}
