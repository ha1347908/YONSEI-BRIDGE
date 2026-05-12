import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'saved_posts_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_analytics_dashboard_screen.dart';
import 'chat_screen.dart';
import 'admin_chat_list_screen.dart';
import 'admin_send_message_screen.dart';
import 'bridge_live_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _unreadRecoveryCount = 0;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadRecoveryCount();
    _loadUnreadChatCount();
  }

  Future<void> _loadUnreadRecoveryCount() async {
    final prefs = await SharedPreferences.getInstance();
    final notifs = prefs.getStringList('admin_recovery_notifications') ?? [];
    int unread = 0;
    for (final n in notifs) {
      try {
        final map = jsonDecode(n) as Map<String, dynamic>;
        if (map['read'] == false) unread++;
      } catch (_) {}
    }
    if (mounted) setState(() => _unreadRecoveryCount = unread);
  }

  Future<void> _loadUnreadChatCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserId;
    if (userId == null || userId.isEmpty) return;
    // 관리자: 전체 unread_by_admin 합산 / 일반 사용자: 자신의 unread_by_user
    try {
      if (authService.currentUserId == 'welovejesus') {
        // 관리자는 chats 컬렉션 전체에서 합산 (간단히 snapshot 1회 조회)
        final snap = await FirestoreService().chatsCol.get();
        int total = 0;
        for (final doc in snap.docs) {
          total += ((doc.data()['unread_by_admin'] as num?) ?? 0).toInt();
        }
        if (mounted) setState(() => _unreadChatCount = total);
      } else {
        final doc = await FirestoreService().chatsCol.doc(userId).get();
        if (doc.exists) {
          final count =
              ((doc.data()?['unread_by_user'] as num?) ?? 0).toInt();
          if (mounted) setState(() => _unreadChatCount = count);
        }
      }
    } catch (_) {}
  }

  Future<void> _handleLogout(BuildContext context) async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('logout')),
        content: Text(lang.translate('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(lang.translate('logout')),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      Provider.of<StorageService>(context, listen: false).setCurrentUser(null);
      await authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('delete_account')),
        content: Text(lang.translate('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(lang.translate('delete')),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      Provider.of<StorageService>(context, listen: false).setCurrentUser(null);
      await authService.logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('delete_account_complete'))),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showLanguageDialog(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.translate('language_select')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption(dialogContext, lang, '한국어', 'ko'),
            _buildLangOption(dialogContext, lang, 'English', 'en'),
            _buildLangOption(dialogContext, lang, '中文', 'zh'),
            _buildLangOption(dialogContext, lang, '日本語', 'ja'),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(BuildContext dialogContext, LanguageService lang, String name, String code) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: lang.currentLanguage,
      activeColor: const Color(0xFF0038A8),
      onChanged: (value) async {
        await lang.setLanguage(value!);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
        title: Text(lang.translate('my_page'), style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // 프로필 섹션
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0038A8), Color(0xFF6B4EFF)],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      (authService.currentUserName?.isNotEmpty == true)
                          ? authService.currentUserName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.currentUserName ?? lang.translate('student'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authService.isAnyAdmin ? '관리자' : lang.translate('student'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 내 활동
            _buildSectionHeader('내 활동'),
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Color(0xFF0038A8)),
              title: Text(lang.translate('saved_posts')),
              subtitle: const Text('스크랩한 게시물 모음'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
              ),
            ),
            // ── 채팅 항목 ────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF0038A8)),
              title: Text(
                authService.currentUserId == 'welovejesus'
                    ? lang.translate('admin_chat_manage')
                    : lang.translate('chat_with_admin'),
              ),
              subtitle: Text(
                authService.currentUserId == 'welovejesus'
                    ? lang.translate('admin_chat_manage_desc')
                    : lang.translate('chat_with_admin_desc'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_unreadChatCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _unreadChatCount > 99
                            ? '99+'
                            : '$_unreadChatCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                if (authService.currentUserId == 'welovejesus') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminChatListScreen()),
                  ).then((_) => _loadUnreadChatCount());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChatScreen()),
                  ).then((_) => _loadUnreadChatCount());
                }
              },
            ),

            // ── Bridge Live ──────────────────────────────────────────
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A0E27), Color(0xFF1A1F40)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.radio_button_checked,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
              ),
              title: const Text(
                'Bridge Live',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('한국어 음성 → 내 언어로 실시간 번역'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BridgeLiveScreen()),
              ),
            ),

            // ── 개별 메시지 발송 (welovejesus 관리자 전용) ──────────────
            if (authService.currentUserId == 'welovejesus') ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.send_outlined,
                    color: Color(0xFF0038A8)),
                title: const Text('개별 메시지 발송'),
                subtitle: const Text('사용자를 선택해 각각 메시지를 보냅니다'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminSendMessageScreen()),
                  );
                },
              ),
            ],

            const Divider(height: 1),

            // 앱 설정
            _buildSectionHeader(lang.translate('app_settings')),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(lang.translate('language')),
              subtitle: Text(_getLangName(lang.currentLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context, lang),
            ),

            const Divider(height: 1),

            // 관리자 섹션
            if (authService.isFullAdmin) ...[
              _buildSectionHeader('관리자 기능'),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF0038A8)),
                title: const Text('회원 승인 관리'),
                subtitle: const Text('가입 신청 승인/거부/차단'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_unreadRecoveryCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadRecoveryCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
                  ).then((_) => _loadUnreadRecoveryCount());
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics, color: Color(0xFF0038A8)),
                title: const Text('데이터 분석 대시보드'),
                subtitle: const Text('DAU, 활성도, 신규 가입자 통계'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnalyticsDashboardScreen()),
                ),
              ),
              const Divider(height: 1),
            ],

            // 정보
            _buildSectionHeader(lang.translate('info')),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(lang.translate('terms_of_service')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(lang.translate('privacy_policy')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(lang.translate('app_version')),
              subtitle: const Text('1.0.0'),
            ),

            const Divider(height: 1),

            // 계정
            _buildSectionHeader(lang.translate('account')),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: Text(
                lang.translate('logout'),
                style: const TextStyle(color: Colors.orange),
              ),
              onTap: () => _handleLogout(context),
            ),
            if (authService.canDeleteAccount)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  lang.translate('delete_account'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _handleDeleteAccount(context),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getLangName(String code) {
    switch (code) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      default: return '한국어';
    }
  }
}
