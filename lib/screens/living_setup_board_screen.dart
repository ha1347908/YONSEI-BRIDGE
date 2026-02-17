import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../models/user_profile_extended.dart';
import 'profile_setup_screen.dart';

class LivingSetupBoardScreen extends StatefulWidget {
  const LivingSetupBoardScreen({super.key});

  @override
  State<LivingSetupBoardScreen> createState() => _LivingSetupBoardScreenState();
}

class _LivingSetupBoardScreenState extends State<LivingSetupBoardScreen> {
  bool _isProfileCompleted = false;
  bool _isLoading = true;
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final profileCompleted = prefs.getBool('living_setup_profile_completed') ?? false;
    final welcomeShown = prefs.getBool('living_setup_welcome_shown') ?? false;
    
    setState(() {
      _isProfileCompleted = profileCompleted;
      _hasShownWelcome = welcomeShown;
      _isLoading = false;
    });

    // Show dialogs after build completes
    if (!_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasShownWelcome) {
          _showWelcomeDialog();
        }
      });
    }
  }

  Future<void> _showWelcomeDialog() async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_filled,
                      size: 80,
                      color: Color(0xFF0038A8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getLocalizedText(lang, 'welcome_title'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0038A8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getLocalizedText(lang, 'welcome_message'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSubscriptionDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0038A8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _getLocalizedText(lang, 'continue'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSubscriptionDialog() async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Special offer badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getLocalizedText(lang, 'special_offer'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Color(0xFF6B4EFF),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getLocalizedText(lang, 'subscription_title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0038A8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Original price (crossed out)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getLocalizedText(lang, 'original_price'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Free for 1 year
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getLocalizedText(lang, 'free_year'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4EFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getLocalizedText(lang, 'subscription_details'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await prefs.setBool('living_setup_welcome_shown', true);
                        setState(() => _hasShownWelcome = true);
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _getLocalizedText(lang, 'start_now'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLocalizedText(LanguageService lang, String key) {
    final langCode = lang.currentLanguage;
    
    final texts = {
      'welcome_title': {
        'ko': '리빙셋업에 오신 것을 환영합니다!',
        'en': 'Welcome to Living Setup!',
        'zh': '欢迎来到生活设置！',
        'ja': 'リビングセットアップへようこそ！',
      },
      'welcome_message': {
        'ko': '연세대 미래캠퍼스 유학생을 위한 맞춤형 정착 가이드입니다. 입국부터 일상생활까지 필요한 모든 정보를 제공합니다.',
        'en': 'A personalized settlement guide for international students at Yonsei Mirae Campus. We provide all the information you need from entry to daily life.',
        'zh': '为延世大学未来校区留学生提供的个性化定居指南。提供从入境到日常生活所需的所有信息。',
        'ja': '延世大学未来キャンパス留学生のための個別定住ガイドです。入国から日常生活まで必要なすべての情報を提供します。',
      },
      'continue': {
        'ko': '계속',
        'en': 'Continue',
        'zh': '继续',
        'ja': '続ける',
      },
      'special_offer': {
        'ko': '🎁 특별 혜택',
        'en': '🎁 Special Offer',
        'zh': '🎁 特别优惠',
        'ja': '🎁 特別オファー',
      },
      'subscription_title': {
        'ko': '지금 가입하면\n1년 무료!',
        'en': 'Sign Up Now\n1 Year Free!',
        'zh': '现在注册\n免费一年！',
        'ja': '今登録すれば\n1年無料！',
      },
      'original_price': {
        'ko': '월 1 USD',
        'en': '1 USD/month',
        'zh': '每月1美元',
        'ja': '月1ドル',
      },
      'free_year': {
        'ko': '1년 무료',
        'en': '1 Year FREE',
        'zh': '免费一年',
        'ja': '1年間無料',
      },
      'subscription_details': {
        'ko': '첫 가입 유학생 대상 1년 무료 이용\n이후 월 1 USD로 모든 서비스 이용 가능',
        'en': 'First-time users get 1 year free\nThen only 1 USD/month for all services',
        'zh': '首次注册用户免费使用1年\n之后每月仅需1美元即可使用所有服务',
        'ja': '初回登録ユーザーは1年間無料\nその後、月額1ドルですべてのサービスを利用可能',
      },
      'start_now': {
        'ko': '지금 시작하기',
        'en': 'Start Now',
        'zh': '立即开始',
        'ja': '今すぐ始める',
      },
      'setup_profile': {
        'ko': '내 정보 입력하기',
        'en': 'Setup My Profile',
        'zh': '输入我的信息',
        'ja': 'マイプロフィール設定',
      },
      'view_profile': {
        'ko': '내 정보 보기',
        'en': 'View My Profile',
        'zh': '查看我的信息',
        'ja': 'マイプロフィール表示',
      },
      'living_setup_guide': {
        'ko': '리빙셋업 가이드',
        'en': 'Living Setup Guide',
        'zh': '生活设置指南',
        'ja': 'リビングセットアップガイド',
      },
      'personalized_posts': {
        'ko': '맞춤 게시물',
        'en': 'Personalized Posts',
        'zh': '个性化帖子',
        'ja': 'パーソナライズされた投稿',
      },
      'no_posts_yet': {
        'ko': '아직 게시물이 없습니다',
        'en': 'No posts yet',
        'zh': '暂无帖子',
        'ja': 'まだ投稿がありません',
      },
      'complete_profile_first': {
        'ko': '내 정보를 입력하면 맞춤형 정보를 받을 수 있습니다',
        'en': 'Complete your profile to receive personalized information',
        'zh': '填写您的信息以接收个性化信息',
        'ja': 'プロフィールを完成させてパーソナライズされた情報を受け取る',
      },
    };
    
    return texts[key]?[langCode] ?? texts[key]?['en'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Consumer<LanguageService>(
            builder: (context, lang, _) => Text(_getLocalizedText(lang, 'living_setup_guide')),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, lang, _) => Text(_getLocalizedText(lang, 'living_setup_guide')),
        ),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: _isProfileCompleted ? _buildProfileCompletedView() : _buildProfileIncompleteView(),
    );
  }

  Widget _buildProfileIncompleteView() {
    return Consumer<LanguageService>(
      builder: (context, lang, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0038A8), Color(0xFF6B4EFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 60, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _getLocalizedText(lang, 'complete_profile_first'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Setup Profile Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
                    final nickname = prefs.getString('nickname') ?? 'User';
                    
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSetupScreen(
                          userId: userId,
                          nickname: nickname,
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      await _checkProfileStatus();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 24),
                  label: Text(
                    _getLocalizedText(lang, 'setup_profile'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Features explanation
                _buildFeatureCard(
                  icon: Icons.person_outline,
                  title: lang.translate('living_setup_feature1_title'),
                  description: lang.translate('living_setup_feature1_desc'),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.location_on_outlined,
                  title: lang.translate('living_setup_feature2_title'),
                  description: lang.translate('living_setup_feature2_desc'),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.language_outlined,
                  title: lang.translate('living_setup_feature3_title'),
                  description: lang.translate('living_setup_feature3_desc'),
                ),
              ],
            ),
          );
      },
    );
  }

  Widget _buildProfileCompletedView() {
    return Consumer<LanguageService>(
      builder: (context, lang, _) {
        return Column(
          children: [
              // View Profile Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _showProfileDialog(),
                  icon: const Icon(Icons.person, size: 24),
                  label: Text(
                    _getLocalizedText(lang, 'view_profile'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              
              // Personalized Posts Section
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _getLocalizedText(lang, 'no_posts_yet'),
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLocalizedText(lang, 'personalized_posts'),
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0038A8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0038A8), size: 28),
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
                      color: Color(0xFF0038A8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = Provider.of<LanguageService>(context, listen: false);
    
    // Load saved profile data
    final studentType = prefs.getString('living_setup_student_type') ?? 'degree';
    final department = prefs.getString('living_setup_department') ?? '';
    final housingType = prefs.getString('living_setup_housing') ?? '';
    final koreanLevel = prefs.getString('living_setup_korean_level') ?? '';
    final visaType = prefs.getString('living_setup_visa') ?? '';
    final entryDateStr = prefs.getString('living_setup_entry_date');
    final interests = prefs.getStringList('living_setup_interests') ?? [];
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF0038A8), size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'My Profile',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  _buildProfileItem('Student Type', studentType == 'degree' ? 'Degree Student' : 'Exchange/Visiting/Language Student'),
                  _buildProfileItem('Department', DepartmentData.getDepartmentName(department, lang.currentLanguage)),
                  if (housingType.isNotEmpty) _buildProfileItem('Housing', housingType),
                  if (koreanLevel.isNotEmpty) _buildProfileItem('Korean Level', koreanLevel),
                  if (visaType.isNotEmpty) _buildProfileItem('Visa Type', VisaData.getVisaName(visaType, lang.currentLanguage)),
                  if (entryDateStr != null) _buildProfileItem('Entry Date', entryDateStr),
                  if (interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Interests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.map((interest) => Chip(
                        label: Text(InterestTags.getInterestName(interest, lang.currentLanguage)),
                        backgroundColor: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
                        final nickname = prefs.getString('nickname') ?? 'User';
                        
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileSetupScreen(
                              userId: userId,
                              nickname: nickname,
                            ),
                          ),
                        );
                        if (result == true) {
                          await _checkProfileStatus();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
