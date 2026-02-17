import 'package:flutter/material.dart';

class NeedJobConversionScreen extends StatelessWidget {
  final String period;
  
  const NeedJobConversionScreen({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('니드잡 지원 전환율'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('NeedJob Conversion Screen - Coming Soon'),
      ),
    );
  }
}
