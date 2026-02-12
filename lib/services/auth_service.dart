import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoggedIn = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> login(String userId, String userName, bool rememberMe) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUserName = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');

    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (_isLoggedIn) {
      _currentUserId = prefs.getString('userId');
      _currentUserName = prefs.getString('userName');
    }
    notifyListeners();
  }
}
