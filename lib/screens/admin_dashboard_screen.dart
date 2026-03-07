import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/language_service.dart';
import 'admin_approval_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _pendingApprovals = 0;
  int _totalInfoPosts = 0;
  int _totalFreePosts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int userCount = 0;
    int pendingCount = 0;
    for (final key in keys) {
      if (key.startsWith('demo_user_')) {
        userCount++;
        final status = prefs.getString('demo_status_${key.replaceFirst("demo_user_", "")}') ?? 'Pending';
        if (status == 'Pending') pendingCount++;
      }
    }

    // Count posts
    final infoPostsJson = prefs.getString('posts_info_board') ?? '[]';
    final freePostsJson = prefs.getString('posts_free_board') ?? '[]';

    setState(() {
      _totalUsers = userCount;
      _pendingApprovals = pendingCount;
      try {
        final infoList = (jsonDecode(infoPostsJson) as List).length;
        final freeList = (jsonDecode(freePostsJson) as List).length;
        _totalInfoPosts = infoList;
        _totalFreePosts = freeList;
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0038A8), Color(0xFF6B4EFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dashboard, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'YONSEI BRIDGE',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('관리자 대시보드', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('📈 주요 통계', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(icon: Icons.people, title: '총 사용자', count: _totalUsers, color: Colors.blue),
                  _buildStatCard(icon: Icons.pending_actions, title: '승인 대기', count: _pendingApprovals, color: Colors.red),
                  _buildStatCard(icon: Icons.article, title: '정보 게시물', count: _totalInfoPosts, color: Colors.green),
                  _buildStatCard(icon: Icons.forum, title: '자유 게시물', count: _totalFreePosts, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              const Text('⚙️ 관리 기능', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildManagementCard(
                icon: Icons.admin_panel_settings,
                title: '회원 승인 관리',
                subtitle: '가입 신청 승인/거부/차단',
                color: const Color(0xFF0038A8),
                count: _pendingApprovals,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
                ).then((_) => _loadDashboardData()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
