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
      // ── 관리자는 Firebase Auth를 사용하지 않으므로, 혹시 남아있는
      //    Firebase Auth 세션을 반드시 제거합니다.
      //    (웹에서 이전 일반유저 세션이 남으면 Firestore 규칙이 엉뚱한
      //     request.auth.uid 로 평가돼 permission-denied 가 발생합니다.)
      if (_auth.currentUser != null) {
        await _auth.signOut();
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

      UserCredential? credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authEx) {
        // Firebase Auth not activated → fallback to Firestore-only login
        if (authEx.code == 'operation-not-allowed' ||
            authEx.code == 'configuration-not-found' ||
            authEx.code == 'channel-error' ||
            authEx.code == 'admin-restricted-operation') {
          if (kDebugMode) debugPrint('[AuthService] Firebase Auth not enabled, falling back to Firestore login');
          await _firestoreFallbackLogin(email, password, rememberMe);
          return;
        }
        rethrow;
      }

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

  /// Firestore-only login fallback (when Firebase Auth is not yet enabled)
  Future<void> _firestoreFallbackLogin(
    String email,
    String password,
    bool rememberMe,
  ) async {
    // Find user by email in Firestore
    final userData = await _fs.getUserByEmail(email);
    if (userData == null) {
      throw Exception('No account found with that email address. Please sign up first.');
    }

    // Check stored password (plain text fallback - only used before Auth is enabled)
    final storedPassword = userData['password'] as String?;
    if (storedPassword != null && storedPassword != password) {
      throw Exception('Incorrect email or password.');
    }

    final status = userData['status'] as String? ?? 'Pending';
    switch (status) {
      case 'Pending':
        throw PendingApprovalException();
      case 'Blocked':
        throw BlockedException(userData['status_reason'] as String?);
      case 'Rejected':
        throw RejectedException(userData['status_reason'] as String?);
      case 'Approved':
        break;
      default:
        throw Exception('Account status: $status');
    }

    final nickname = userData['nickname'] as String?;
    final name = userData['name'] as String?;
    final uid = userData['uid'] as String? ?? email;

    await _setSession(
      userId: uid,
      userName: nickname ?? name ?? email,
      permission: userData['permission'] as String? ?? 'user',
      canDelete: true,
      rememberMe: rememberMe,
    );
  }

  Future<String> signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String nationality,
    required String contact,
    String? idPhotoBase64,
  }) async {
    // Validate inputs before calling Firebase
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.isEmpty || password.length < 8) {
      throw Exception('Password must be at least 8 characters.');
    }

    String? createdUid;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUid = credential.user!.uid;

      // Create Firestore user document (status = Pending)
      await _fs.createUser(
        uid: createdUid,
        email: email.trim(),
        name: name,
        nickname: nickname,
        nationality: nationality,
        contact: contact,
        status: 'Pending',
        role: 'User',
        permission: 'user',
        password: password,
        idPhotoBase64: idPhotoBase64,
      );

      // Sign out immediately — user must wait for admin approval
      await _auth.signOut();
      return createdUid;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('[AuthService] signUp FirebaseAuthException code=${e.code} msg=${e.message}');
      // Firebase Auth not enabled yet → fallback: save to Firestore only
      if (e.code == 'operation-not-allowed' ||
          e.code == 'configuration-not-found' ||
          e.code == 'channel-error' ||
          e.code == 'admin-restricted-operation') {
        // Use email as document ID (safe fallback)
        final fallbackUid = 'pending_${email.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        await _fs.createUser(
          uid: fallbackUid,
          email: email.trim(),
          name: name,
          nickname: nickname,
          nationality: nationality,
          contact: contact,
          status: 'Pending',
          role: 'User',
          permission: 'user',
          password: password,
          idPhotoBase64: idPhotoBase64,
        );
        return fallbackUid;
      }
      // email-already-in-use: Firebase Auth에 계정이 이미 있으면
      // Firestore에도 문서가 있는지 확인
      if (e.code == 'email-already-in-use') {
        final existing = await _fs.getUserByEmail(email.trim());
        if (existing != null) {
          // Firestore에도 있으면 → 이미 가입된 계정
          throw Exception('This email is already registered. Please log in or use Account Recovery.');
        } else {
          // Firebase Auth에만 있고 Firestore에 없으면 → 이전 가입 실패 잔여
          // 사용자가 직접 로그인해서 삭제할 수 없으므로 안내 메시지 제공
          throw Exception('A previous sign-up attempt did not complete. Please contact the administrator at iamharam@yonsei.ac.kr to reset your account.');
        }
      }
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      // Firestore 저장 실패 시 Firebase Auth 계정 롤백
      if (createdUid != null) {
        try {
          await _auth.currentUser?.delete();
        } catch (_) {}
      }
      if (kDebugMode) debugPrint('[AuthService] signUp error: $e');
      rethrow;
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
    // ── 이름 확정 로직 ───────────────────────────────────────────────────────
    // 관리자 계정은 하드코딩 이름을 그대로 사용.
    // 일반 유저는 Firestore에서 nickname → name → emailOrId 순으로 확정.
    // (userName 파라미터가 이미 올바른 닉네임이어도 Firestore로 재확인해
    //  가장 최신 값을 저장한다.)
    String resolvedName = userName;
    final isAdmin = _adminAccounts.containsKey(userId);

    if (!isAdmin) {
      try {
        final userData = await _fs.getUser(userId);
        if (userData != null) {
          final nickname = userData['nickname'] as String?;
          final name     = userData['name']     as String?;
          if (nickname != null && nickname.isNotEmpty) {
            resolvedName = nickname;
          } else if (name != null && name.isNotEmpty) {
            resolvedName = name;
          }
          // userData에서 permission도 최신으로 갱신
        }
      } catch (_) {
        // 네트워크 오류 → 파라미터로 받은 userName 사용
      }
    }

    // 최후 안전망: 빈 값이면 userId 표시
    if (resolvedName.isEmpty || resolvedName == 'Unknown') {
      resolvedName = userId;
    }

    _currentUserId         = userId;
    _currentUserName       = resolvedName;
    _currentUserPermission = permission;
    _canDeleteAccount      = canDelete;
    _isLoggedIn            = true;

    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', resolvedName);      // ← 검증된 이름 저장
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

    if (!_isLoggedIn) {
      notifyListeners();
      return;
    }

    // SharedPreferences에서 기본값 복원
    _currentUserId         = prefs.getString('userId');
    _currentUserName       = prefs.getString('userName');
    _currentUserPermission = prefs.getString('userPermission') ?? 'user';
    _canDeleteAccount      = prefs.getBool('canDeleteAccount') ?? true;

    final userId = _currentUserId;
    if (userId == null) {
      // userId가 없으면 세션 무효
      await logout();
      return;
    }

    final isAdminAccount = _adminAccounts.containsKey(userId);

    if (isAdminAccount) {
      // 관리자 계정은 하드코딩 데이터로 복원
      // Firebase Auth 세션이 남아있으면 제거 (permission-denied 방지)
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      final account = _adminAccounts[userId]!;
      _currentUserName       = account['name'] as String;
      _currentUserPermission = account['permissions'] as String;
      _canDeleteAccount      = account['can_delete_account'] as bool;
      _isLoggedIn            = true;
      notifyListeners();
      return;
    }

    // ────────────────────────────────────────────────────────────────────────
    // 일반 Firebase 유저:
    // 1) Firebase Auth 세션이 살아있지 않으면 Firestore Security Rules 때문에
    //    getUser() 가 Permission Denied 가 될 수 있음 → 먼저 Auth 상태 확인
    // 2) Firestore에서 최신 이름·권한을 항상 가져와 덮어씀
    // ────────────────────────────────────────────────────────────────────────
    try {
      // Firebase Auth persistence 는 기본 LOCAL → 앱 재시작 후에도 currentUser 복원됨.
      // currentUser 가 null 이면 세션이 만료된 것이므로 로그아웃 처리.
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        // Firebase Auth 세션 없음 → SharedPreferences 세션도 정리
        if (kDebugMode) debugPrint('[AuthService] checkLoginStatus: Firebase Auth session expired, logging out');
        await logout();
        return;
      }

      // Firestore에서 최신 프로필 조회
      final userData = await _fs.getUser(userId);
      if (userData == null) {
        // Firestore 에 유저 문서가 없는 경우 → 세션 정리
        if (kDebugMode) debugPrint('[AuthService] checkLoginStatus: Firestore doc not found for $userId');
        await logout();
        return;
      }

      final nickname = userData['nickname'] as String?;
      final name     = userData['name']     as String?;
      final freshName = (nickname != null && nickname.isNotEmpty)
          ? nickname
          : (name != null && name.isNotEmpty)
              ? name
              : _currentUserName; // 최후 fallback: 기존 저장값

      _currentUserName       = freshName ?? userId;
      _currentUserPermission = (userData['permission'] as String?)?.isNotEmpty == true
          ? userData['permission'] as String
          : _currentUserPermission ?? 'user';
      _isLoggedIn = true;

      // 갱신된 값을 SharedPreferences에 덮어써서 다음 앱 재시작에도 반영
      await prefs.setString('userName',       _currentUserName ?? '');
      await prefs.setString('userPermission', _currentUserPermission ?? 'user');

    } catch (e) {
      // 네트워크 오류 등 → SharedPreferences 기존 값으로 계속 진행
      if (kDebugMode) debugPrint('[AuthService] checkLoginStatus Firestore refresh failed: $e');
      // userName 이 여전히 비어있거나 Unknown 이면 userId를 그대로 표시
      if (_currentUserName == null || _currentUserName!.isEmpty || _currentUserName == 'Unknown') {
        _currentUserName = userId;
      }
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
