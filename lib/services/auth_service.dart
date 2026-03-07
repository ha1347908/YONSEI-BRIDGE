import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Wraps Firebase Auth and exposes user state to the app.
///
/// Admin accounts (hardcoded) bypass Firebase Auth for backward compatibility
/// and are kept in SharedPreferences exactly as before.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

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

  // ── Permission helpers ───────────────────────────────────────────────────
  bool get isFullAdmin => _currentUserPermission == 'full_admin';
  bool get isPostOnlyAdmin => _currentUserPermission == 'post_only';
  bool get isAnyAdmin => isFullAdmin || isPostOnlyAdmin;

  bool get isMainAdmin =>
      _currentUserId == 'welovejesus' ||
      _currentUserId == 'bridge_master_haram' ||
      _currentUserId == 'bridge_master_jose';

  // ── Hardcoded admin accounts (not in Firebase Auth) ──────────────────────
  static const Map<String, Map<String, dynamic>> _adminAccounts = {
    'welovejesus': {
      'password': 'jesuslovesyou',
      'name': 'System Administrator',
      'status': 'Approved',
      'permissions': 'full_admin',
      'can_delete_account': true,
    },
    'bridge_master_haram': {
      'password': 'ha321281020108!',
      'name': 'Bridge Master Haram',
      'status': 'Approved',
      'permissions': 'full_admin',
      'can_delete_account': false,
    },
    'bridge_master_jose': {
      'password': 'jose2001!',
      'name': 'Bridge Master Jose',
      'status': 'Approved',
      'permissions': 'full_admin',
      'can_delete_account': false,
    },
    'manage_yb2026': {
      'password': '2026manage_yb',
      'name': 'YB Manager 2026',
      'status': 'Approved',
      'permissions': 'post_only',
      'can_delete_account': false,
    },
  };

  // ════════════════════════════════════════════════════════════════════════
  // LOGIN
  // ════════════════════════════════════════════════════════════════════════

  /// Main login entry point.
  /// - Admin IDs → SharedPreferences path (backward compat)
  /// - Everything else → Firebase Auth email/password
  Future<void> loginWithEmailOrId(
    String emailOrId,
    String password,
    bool rememberMe,
  ) async {
    // 1. Admin account check (hardcoded)
    if (_adminAccounts.containsKey(emailOrId)) {
      final account = _adminAccounts[emailOrId]!;
      if (account['password'] != password) {
        throw Exception('Incorrect password');
      }
      await _setSession(
        userId: emailOrId,
        userName: account['name'] as String,
        permission: account['permissions'] as String,
        canDelete: account['can_delete_account'] as bool,
        rememberMe: rememberMe,
      );
      return;
    }

    // 2. Firebase Auth (regular users)
    try {
      // Validate email format before calling Firebase
      final email = emailOrId.trim();
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address (e.g. user@gmail.com)');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Fetch user profile from Firestore
      final userData = await _fs.getUser(uid);
      if (userData == null) {
        await _auth.signOut();
        throw Exception('User profile not found. Please contact the administrator.');
      }

      final status = userData['status'] as String? ?? 'Pending';
      switch (status) {
        case 'Pending':
          await _auth.signOut();
          throw PendingApprovalException();
        case 'Blocked':
          await _auth.signOut();
          throw BlockedException(userData['status_reason'] as String?);
        case 'Rejected':
          await _auth.signOut();
          throw RejectedException(userData['status_reason'] as String?);
        case 'Approved':
          break;
        default:
          await _auth.signOut();
          throw Exception('Account status: $status');
      }

      final nickname = userData['nickname'] as String?;
      final name = userData['name'] as String?;

      await _setSession(
        userId: uid,
        userName: nickname ?? name ?? emailOrId,
        permission: userData['permission'] as String? ?? 'user',
        canDelete: true,
        rememberMe: rememberMe,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] FirebaseAuthException code=${e.code} msg=${e.message}');
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] login error: $e');
      rethrow;
    }
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String nationality,
    required String contact,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      // Create Firestore user document (status = Pending)
      await _fs.createUser(
        uid: uid,
        email: email.trim(),
        name: name,
        nickname: nickname,
        nationality: nationality,
        contact: contact,
        status: 'Pending',
        role: 'User',
        permission: 'user',
      );

      // Sign out immediately — user must wait for admin approval
      await _auth.signOut();
      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNT RECOVERY REQUEST
  // ════════════════════════════════════════════════════════════════════════

  Future<void> submitRecoveryRequest(String email) async {
    // Submit recovery request directly to Firestore
    // (email existence check skipped — fetchSignInMethodsForEmail is deprecated)
    await _fs.submitRecoveryRequest(email.trim());
  }

  // ════════════════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════

  /// Low-level login used by legacy code paths and admin accounts.
  Future<void> login(
    String userId,
    String userName,
    bool rememberMe, {
    String? permission,
    bool? canDelete,
  }) async {
    await _setSession(
      userId: userId,
      userName: userName,
      permission: permission ?? 'user',
      canDelete: canDelete ?? true,
      rememberMe: rememberMe,
    );
  }

  Future<void> _setSession({
    required String userId,
    required String userName,
    required String permission,
    required bool canDelete,
    required bool rememberMe,
  }) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserPermission = permission;
    _canDeleteAccount = canDelete;
    _isLoggedIn = true;

    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
      await prefs.setString('userPermission', permission);
      await prefs.setBool('canDeleteAccount', canDelete);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    // Sign out from Firebase Auth if a Firebase user is active
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }

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
      _currentUserPermission =
          prefs.getString('userPermission') ?? 'user';
      _canDeleteAccount = prefs.getBool('canDeleteAccount') ?? true;
    }
    notifyListeners();
  }

  // ── Firebase Auth error code → readable message ──────────────────────────
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email address. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact the administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact the administrator.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not configured. Please contact the administrator.';
      case 'admin-restricted-operation':
        return 'This operation is restricted. Please contact the administrator.';
      case 'missing-password':
        return 'Please enter your password.';
      case 'missing-email':
        return 'Please enter your email address.';
      case 'channel-error':
        return 'Please enter your email and password.';
      default:
        if (kDebugMode) debugPrint('[AuthService] Unhandled Firebase error code: $code');
        return 'Login failed ($code). Please try again or contact the administrator.';
    }
  }
}

// ── Custom exceptions for status checks ─────────────────────────────────────

class PendingApprovalException implements Exception {
  @override
  String toString() => 'PendingApprovalException';
}

class BlockedException implements Exception {
  final String? reason;
  const BlockedException(this.reason);
  @override
  String toString() => 'BlockedException: $reason';
}

class RejectedException implements Exception {
  final String? reason;
  const RejectedException(this.reason);
  @override
  String toString() => 'RejectedException: $reason';
}
