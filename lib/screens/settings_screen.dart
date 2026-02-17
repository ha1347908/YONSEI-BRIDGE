import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/firebase_storage_service.dart';
import 'login_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePhotoUrl = prefs.getString('profile_photo_url');
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '알림이 켜졌습니다' : '알림이 꺼졌습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showPhotoOptions() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0038A8)),
              title: Text(languageService.translate('select_from_gallery')),
              onTap: () {
                Navigator.pop(context);
                _uploadProfilePhoto(fromGallery: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0038A8)),
              title: Text(languageService.translate('take_photo')),
              onTap: () {
                Navigator.pop(context);
                _uploadProfilePhoto(fromGallery: false);
              },
            ),
            if (_profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  languageService.translate('remove_photo'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePhoto({required bool fromGallery}) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final firebaseStorageService = Provider.of<FirebaseStorageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Pick image
      final imageFile = fromGallery
          ? await firebaseStorageService.pickImageFromGallery()
          : await firebaseStorageService.takePhotoWithCamera();

      if (imageFile == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Upload to Firebase Storage
      final downloadUrl = await firebaseStorageService.uploadProfilePhoto(
        authService.currentUserId ?? 'unknown',
        imageFile,
      );

      if (downloadUrl != null) {
        // Save URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_photo_url', downloadUrl);

        setState(() {
          _profilePhotoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageService.translate('profile_photo_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageService.translate('profile_photo_upload_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final firebaseStorageService = Provider.of<FirebaseStorageService>(context, listen: false);

    if (_profilePhotoUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('remove_photo')),
        content: Text(languageService.translate('remove_photo_confirm')),
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
            child: Text(languageService.translate('remove')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Delete from Firebase Storage
      await firebaseStorageService.deleteProfilePhoto(_profilePhotoUrl!);

      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_photo_url');

      setState(() {
        _profilePhotoUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageService.translate('profile_photo_removed')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

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
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _profilePhotoUrl != null
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _isUploadingPhoto
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                                )
                              : _profilePhotoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color(0xFF0038A8),
                                    )
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0038A8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
              subtitle: Text(_notificationsEnabled ? '알림 켜짐' : '알림 꺼짐'),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: const Color(0xFF0038A8),
              ),
            ),
            
            const Divider(),
            
            // Admin Section (only for full admin users - not post_only)
            if (authService.isFullAdmin) ...[
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
                leading: const Icon(Icons.dashboard, color: Color(0xFF0038A8)),
                title: const Text('관리자 대시보드'),
                subtitle: const Text('시스템 현황 및 통계'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
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
              
              ListTile(
                leading: const Icon(Icons.notifications_active, color: Color(0xFF0038A8)),
                title: const Text('알림 보내기'),
                subtitle: const Text('사용자에게 알림 전송 (국가별 필터링)'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
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
            
            // 탈퇴 불가 계정은 삭제 버튼 숨기기
            if (authService.canDeleteAccount)
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
