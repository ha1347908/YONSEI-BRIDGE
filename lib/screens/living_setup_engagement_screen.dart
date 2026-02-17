import 'package:flutter/material.dart';

class LivingSetupEngagementScreen extends StatelessWidget {
  final String period;
  
  const LivingSetupEngagementScreen({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리빙셋업 클릭 로그'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Living Setup Engagement Screen - Coming Soon'),
      ),
    );
  }
}
