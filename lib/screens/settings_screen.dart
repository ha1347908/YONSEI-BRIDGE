import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'login_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'admin_approval_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleLogout() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('logout')),
        content: Text(languageService.translate('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(languageService.translate('logout')),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('delete_account')),
        content: Text(languageService.translate('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(languageService.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageService.translate('delete_account_complete'))),
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
        title: Text(languageService.translate('settings')),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                languageService.translate('app_settings'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(languageService.translate('language')),
              subtitle: Text(_getLanguageName(languageService.currentLanguage)),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(languageService.translate('language_select')),
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
                                SnackBar(content: Text(languageService.translate('language_changed'))),
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
                                SnackBar(content: Text(languageService.translate('language_changed'))),
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
                                SnackBar(content: Text(languageService.translate('language_changed'))),
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
                                SnackBar(content: Text(languageService.translate('language_changed'))),
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
              title: Text(languageService.translate('notification_settings')),
              subtitle: Text(languageService.translate('push_notification_manage')),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${languageService.translate('notification_settings')} - ${languageService.translate('coming_soon')}')),
                );
              },
            ),
            
            const Divider(),
            
            // Admin Section (only for admin users)
            if (authService.currentUserId == 'admin') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  '관리자',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF0038A8)),
                title: const Text('회원 승인 관리'),
                subtitle: const Text('가입 신청 승인/거부'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
                  );
                },
              ),
              
              const Divider(),
            ],
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                languageService.translate('account'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(languageService.translate('profile_edit')),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${languageService.translate('profile_edit')} - ${languageService.translate('coming_soon')}')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: Text(
                languageService.translate('logout'),
                style: const TextStyle(color: Colors.orange),
              ),
              onTap: _handleLogout,
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                languageService.translate('delete_account'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _handleDeleteAccount,
            ),
            
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                languageService.translate('info'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(languageService.translate('app_version')),
              subtitle: const Text('1.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(languageService.translate('terms_of_service')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(languageService.translate('privacy_policy')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
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
