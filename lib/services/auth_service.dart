import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPermission;
  bool _canDeleteAccount = true;
  bool _isLoggedIn = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserPermission => _currentUserPermission;
  bool get canDeleteAccount => _canDeleteAccount;
  bool get isLoggedIn => _isLoggedIn;

  // 권한 체크 헬퍼 메서드들
  bool get isFullAdmin => _currentUserPermission == 'full_admin';
  bool get isPostOnlyAdmin => _currentUserPermission == 'post_only';
  bool get isAnyAdmin => isFullAdmin || isPostOnlyAdmin;
  
  // 특정 관리자 ID 체크
  bool get isMainAdmin {
    return _currentUserId == 'welovejesus' ||
           _currentUserId == 'bridge_master_haram' ||
           _currentUserId == 'bridge_master_jose';
  }

  Future<void> login(String userId, String userName, bool rememberMe, 
      {String? permission, bool? canDelete}) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserPermission = permission ?? 'user';
    _canDeleteAccount = canDelete ?? true;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
      await prefs.setString('userPermission', _currentUserPermission ?? 'user');
      await prefs.setBool('canDeleteAccount', _canDeleteAccount);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUserName = null;
    _currentUserPermission = null;
    _canDeleteAccount = true;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userPermission');
    await prefs.remove('canDeleteAccount');

    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (_isLoggedIn) {
      _currentUserId = prefs.getString('userId');
      _currentUserName = prefs.getString('userName');
      _currentUserPermission = prefs.getString('userPermission') ?? 'user';
      _canDeleteAccount = prefs.getBool('canDeleteAccount') ?? true;
    }
    notifyListeners();
  }
}
