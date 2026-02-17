import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/permission_service.dart';
import 'board_screen.dart';
import 'saved_posts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions only once (on first launch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsOnce();
    });
  }

  Future<void> _requestPermissionsOnce() async {
    if (!mounted) return;
    
    // Check if permissions have already been requested
    final prefs = await SharedPreferences.getInstance();
    final permissionsRequested = prefs.getBool('permissions_requested') ?? false;
    
    if (!permissionsRequested) {
      await PermissionService.requestAllPermissions(context);
      // Mark as requested
      await prefs.setBool('permissions_requested', true);
    }
  }

  List<BoardCategory> _getCategories(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return [
      BoardCategory(
        id: 'free_board',
        title: lang.translate('free_board'),
        icon: Icons.forum,
        color: const Color(0xFF0038A8),
        description: lang.translate('free_board_desc'),
        allowUserPost: true,
      ),
      BoardCategory(
        id: 'living_setup',
        title: lang.translate('living_setup'),
        icon: Icons.home_work,
        color: const Color(0xFF6B4EFF),
        description: lang.translate('living_setup_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'transportation',
        title: lang.translate('transportation'),
        icon: Icons.directions_bus,
        color: const Color(0xFF00BCD4),
        description: lang.translate('transportation_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'useful_info',
        title: lang.translate('useful_info'),
        icon: Icons.lightbulb,
        color: const Color(0xFFFF9800),
        description: lang.translate('useful_info_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'campus_info',
        title: lang.translate('campus_info'),
        icon: Icons.school,
        color: const Color(0xFF4CAF50),
        description: lang.translate('campus_info_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'need_job',
        title: lang.translate('need_job'),
        icon: Icons.work,
        color: const Color(0xFFE91E63),
        description: lang.translate('need_job_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'hospital_info',
        title: lang.translate('hospital_info'),
        icon: Icons.local_hospital,
        color: const Color(0xFFF44336),
        description: lang.translate('hospital_info_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'restaurants',
        title: lang.translate('restaurants'),
        icon: Icons.restaurant,
        color: const Color(0xFF795548),
        description: lang.translate('restaurants_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'clubs',
        title: lang.translate('clubs'),
        icon: Icons.groups,
        color: const Color(0xFF9C27B0),
        description: lang.translate('clubs_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'korean_exchange',
        title: lang.translate('korean_exchange'),
        icon: Icons.language,
        color: const Color(0xFF3F51B5),
        description: lang.translate('korean_exchange_desc'),
        allowUserPost: false,
      ),
      BoardCategory(
        id: 'about',
        title: lang.translate('about'),
        icon: Icons.info,
        color: const Color(0xFF607D8B),
        description: lang.translate('about_desc'),
        allowUserPost: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final categories = _getCategories(context);
    
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
            tooltip: languageService.translate('saved_posts'),
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
            tooltip: languageService.translate('settings'),
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
                      '${languageService.translate('welcome_message')}, ${authService.currentUserName ?? languageService.translate('student')}${languageService.translate('greeting')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageService.translate('we_connect_people'),
                      style: const TextStyle(
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
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
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
