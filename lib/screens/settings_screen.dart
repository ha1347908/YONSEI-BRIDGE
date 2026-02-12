import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n\n'
          '모든 데이터가 삭제되며, 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴가 완료되었습니다')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // User profile section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0038A8),
                    Color(0xFF6B4EFF),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF0038A8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authService.currentUserName ?? '사용자',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authService.currentUserId ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings sections
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '앱 설정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('언어 설정'),
              subtitle: Text(_getLanguageName(languageService.currentLanguage)),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('언어 선택'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                          title: const Text('한국어'),
                          value: 'ko',
                          groupValue: languageService.currentLanguage,
                          onChanged: (value) async {
                            await languageService.setLanguage(value as String);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('언어가 변경되었습니다')),
                              );
                            }
                          },
                        ),
                        RadioListTile(
                          title: const Text('English'),
                          value: 'en',
                          groupValue: languageService.currentLanguage,
                          onChanged: (value) async {
                            await languageService.setLanguage(value as String);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Language changed')),
                              );
                            }
                          },
                        ),
                        RadioListTile(
                          title: const Text('中文'),
                          value: 'zh',
                          groupValue: languageService.currentLanguage,
                          onChanged: (value) async {
                            await languageService.setLanguage(value as String);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('语言已更改')),
                              );
                            }
                          },
                        ),
                        RadioListTile(
                          title: const Text('日本語'),
                          value: 'ja',
                          groupValue: languageService.currentLanguage,
                          onChanged: (value) async {
                            await languageService.setLanguage(value as String);
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('言語が変更されました')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알림 설정'),
              subtitle: const Text('푸시 알림 관리'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정 - 준비 중')),
                );
              },
            ),
            
            const Divider(),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '계정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('프로필 편집'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로필 편집 - 준비 중')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: _handleLogout,
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                '회원 탈퇴',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _handleDeleteAccount,
            ),
            
            const Divider(),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('앱 버전'),
              subtitle: Text('1.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('이용약관'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이용약관 - 준비 중')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('개인정보처리방침'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('개인정보처리방침 - 준비 중')),
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return '한국어';
    }
  }
}
