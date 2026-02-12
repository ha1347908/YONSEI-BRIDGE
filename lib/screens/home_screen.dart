import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'board_screen.dart';
import 'saved_posts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<BoardCategory> _categories = [
    BoardCategory(
      id: 'free_board',
      title: '자유게시판',
      icon: Icons.forum,
      color: const Color(0xFF0038A8),
      description: '누구나 자유롭게 글을 작성할 수 있습니다',
      allowUserPost: true,
    ),
    BoardCategory(
      id: 'living_setup',
      title: '리빙셋업',
      icon: Icons.home_work,
      color: const Color(0xFF6B4EFF),
      description: '입국부터 정착까지 단계별 가이드',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'transportation',
      title: '원주시 교통정보',
      icon: Icons.directions_bus,
      color: const Color(0xFF00BCD4),
      description: '버스, 택시, 교통편 정보',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'useful_info',
      title: '유용한 정보글',
      icon: Icons.lightbulb,
      color: const Color(0xFFFF9800),
      description: '생활 꿀팁과 유용한 정보',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'campus_info',
      title: '미래캠퍼스 정보',
      icon: Icons.school,
      color: const Color(0xFF4CAF50),
      description: '캠퍼스 시설, 학사 일정 정보',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'need_job',
      title: '니드잡',
      icon: Icons.work,
      color: const Color(0xFFE91E63),
      description: '유학생 특화 구인 정보',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'hospital_info',
      title: '원주시 병원정보',
      icon: Icons.local_hospital,
      color: const Color(0xFFF44336),
      description: '병원 정보 및 의료 지원',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'restaurants',
      title: '원주시 맛집, 카페',
      icon: Icons.restaurant,
      color: const Color(0xFF795548),
      description: '맛집과 카페 추천',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'clubs',
      title: '동아리 소개',
      icon: Icons.groups,
      color: const Color(0xFF9C27B0),
      description: '미래캠퍼스 동아리 정보',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'korean_exchange',
      title: '한국 학생과의 교류',
      icon: Icons.language,
      color: const Color(0xFF3F51B5),
      description: '한국 학생들과 소통하기',
      allowUserPost: false,
    ),
    BoardCategory(
      id: 'about',
      title: '연세브릿지에 대하여',
      icon: Icons.info,
      color: const Color(0xFF607D8B),
      description: '앱 소개 및 이용 안내',
      allowUserPost: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: const Text('YONSEI BRIDGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedPostsScreen(),
                ),
              );
            },
            tooltip: '저장된 게시물',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0038A8),
                      const Color(0xFF6B4EFF),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕하세요, ${authService.currentUserName ?? "학생"}님!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WE CONNECT PEOPLE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Board categories grid
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BoardCategory category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BoardScreen(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color,
                category.color.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  category.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoardCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool allowUserPost;

  BoardCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.allowUserPost,
  });
}
