import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import 'admin_resume_list_screen.dart';
import 'admin_statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalResumes = 0;
  int _totalSymptomCards = 0;
  int _pendingApprovals = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Count users
    int userCount = 0;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('demo_user_')) {
        userCount++;
      }
    }

    // Count resumes (stored with 'resume_' prefix)
    int resumeCount = 0;
    for (final key in keys) {
      if (key.startsWith('resume_')) {
        resumeCount++;
      }
    }

    // Count symptom cards (stored with 'symptom_card_' prefix)
    int symptomCardCount = 0;
    for (final key in keys) {
      if (key.startsWith('symptom_card_')) {
        symptomCardCount++;
      }
    }

    // Count pending approvals (placeholder)
    int pendingCount = 0;

    setState(() {
      _totalUsers = userCount;
      _totalResumes = resumeCount;
      _totalSymptomCards = symptomCardCount;
      _pendingApprovals = pendingCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

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
              // Welcome card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0038A8),
                      Color(0xFF6B4EFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'YONSEI BRIDGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '관리자 대시보드',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '📊 시스템 현황 한눈에 보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics cards
              const Text(
                '📈 주요 통계',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    title: '총 사용자',
                    count: _totalUsers,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    icon: Icons.description,
                    title: 'NeedJob 이력서',
                    count: _totalResumes,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.medical_services,
                    title: '증상카드',
                    count: _totalSymptomCards,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    icon: Icons.pending_actions,
                    title: '승인 대기',
                    count: _pendingApprovals,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Management sections
              const Text(
                '⚙️ 관리 기능',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Resume management card
              _buildManagementCard(
                icon: Icons.work,
                title: 'NeedJob 이력서 관리',
                subtitle: '제출된 이력서 확인 및 관리',
                color: const Color(0xFF4CAF50),
                count: _totalResumes,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminResumeListScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
              const SizedBox(height: 12),

              // Statistics card
              _buildManagementCard(
                icon: Icons.bar_chart,
                title: '증상카드 통계',
                subtitle: '증상카드 출력 누적 데이터 및 분석',
                color: const Color(0xFFFF9800),
                count: _totalSymptomCards,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStatisticsScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
              const SizedBox(height: 12),

              // User management card
              _buildManagementCard(
                icon: Icons.group,
                title: '사용자 관리',
                subtitle: '전체 사용자 목록 및 정보',
                color: const Color(0xFF2196F3),
                count: _totalUsers,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('사용자 관리 기능 준비 중입니다'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick actions
              const Text(
                '⚡ 빠른 작업',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickActionChip(
                    icon: Icons.refresh,
                    label: '데이터 새로고침',
                    onTap: _loadDashboardData,
                  ),
                  _buildQuickActionChip(
                    icon: Icons.file_download,
                    label: '데이터 내보내기',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('내보내기 기능 준비 중입니다')),
                      );
                    },
                  ),
                  _buildQuickActionChip(
                    icon: Icons.notifications,
                    label: '알림 보내기',
                    onTap: () {
                      Navigator.pop(context); // Go back to settings
                    },
                  ),
                ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[200],
    );
  }
}
