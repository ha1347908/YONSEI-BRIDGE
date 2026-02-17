import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAccountRecoveryDialog() async {
    final emailController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 복구 신청'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '등록된 이메일 주소를 입력하시면, 관리자가 확인 후 복구 승인을 진행합니다.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '등록된 이메일 주소',
                  hintText: 'example@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⏰ 복구 승인까지 1~2일 소요됩니다',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이메일을 입력해주세요')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _submitRecoveryRequest(emailController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0038A8),
              foregroundColor: Colors.white,
            ),
            child: const Text('복구 신청'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRecoveryRequest(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user exists
      final storedUser = prefs.getString('demo_user_$email');
      if (storedUser == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('계정을 찾을 수 없음'),
              content: const Text('입력하신 이메일로 등록된 계정이 없습니다.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Save recovery request
      final recoveryKey = 'recovery_request_$email';
      await prefs.setString(recoveryKey, DateTime.now().toIso8601String());
      await prefs.setString('recovery_status_$email', 'Pending');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('복구 신청 완료'),
            content: const Text(
              '계정 복구 신청이 접수되었습니다.\n\n'
              '관리자가 등록된 이메일로 확인 메일을 발송한 후,\n'
              '수동으로 복구 승인을 진행합니다.\n\n'
              '⏰ 처리 시간: 1~2일 소요\n\n'
              '승인이 완료되면 등록된 이메일로 임시 비밀번호가 발송됩니다.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복구 신청 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text;

        // Demo accounts (hardcoded for testing)
        final demoAccounts = {
          'welovejesus': {
            'password': 'jesuslovesyou',
            'name': 'System Administrator',
            'status': 'Approved',
            'role': 'Admin',
            'permissions': 'full_admin', // 전체 관리자 권한
            'can_delete_account': true,
          },
          'bridge_master_haram': {
            'password': 'ha321281020108!',
            'name': 'Bridge Master Haram',
            'status': 'Approved',
            'role': 'Admin',
            'permissions': 'full_admin',
            'can_delete_account': false, // 탈퇴 불가
          },
          'bridge_master_jose': {
            'password': 'jose2001!',
            'name': 'Bridge Master Jose',
            'status': 'Approved',
            'role': 'Admin',
            'permissions': 'full_admin',
            'can_delete_account': false, // 탈퇴 불가
          },
          'manage_yb2026': {
            'password': '2026manage_yb',
            'name': 'YB Manager 2026',
            'status': 'Approved',
            'role': 'Admin',
            'permissions': 'post_only', // 게시글 작성만 가능
            'can_delete_account': false, // 탈퇴 불가
          },
          'testuser': {
            'password': 'test123',
            'name': '테스트 사용자',
            'status': 'Approved',
            'role': 'User',
            'permissions': 'user',
            'can_delete_account': true,
          },
          'pending_user': {
            'password': 'pending123',
            'name': '대기 중 사용자',
            'status': 'Pending',
            'role': 'User',
            'permissions': 'user',
            'can_delete_account': true,
          },
        };

        // Check if account exists
        if (!demoAccounts.containsKey(username)) {
          // Check local storage for custom registered users
          final prefs = await SharedPreferences.getInstance();
          final storedUser = prefs.getString('demo_user_$username');
          final storedPassword = prefs.getString('demo_password_$username');
          final storedStatus = prefs.getString('demo_status_$username');
          final storedName = prefs.getString('demo_name_$username');
          final storedNickname = prefs.getString('demo_nickname_$username'); // 별명 가져오기
          
          if (storedUser == null) {
            throw Exception('User not found. Please sign up first.');
          }
          
          if (storedPassword != password) {
            throw Exception('Incorrect password');
          }
          
          // Check status for custom users
          if (storedStatus == 'Pending') {
            setState(() {
              _isLoading = false;
            });
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Approval Pending'),
                  content: const Text(
                    'Your account is awaiting administrator approval.\n\n'
                    'Please wait 1-2 days for approval.\n\n'
                    'You will be notified once your account is approved.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          
          if (storedStatus == 'Blocked') {
            final blockReason = prefs.getString('demo_block_reason_$username');
            setState(() {
              _isLoading = false;
            });
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Account Blocked'),
                  content: Text(
                    'Your account has been blocked by the administrator.\n\n'
                    'Reason: ${blockReason ?? "Not specified"}\n\n'
                    'Please contact the administrator for more information.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          
          if (storedStatus == 'Rejected') {
            final rejectionReason = prefs.getString('demo_rejection_reason_$username');
            setState(() {
              _isLoading = false;
            });
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Account Rejected'),
                  content: Text(
                    'Your account registration has been rejected.\n\n'
                    'Reason: ${rejectionReason ?? "Not specified"}\n\n'
                    'Please contact the administrator or register again with correct information.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          
          // Check if status is 'Approved' before allowing login
          if (storedStatus != 'Approved') {
            throw Exception('Account status: $storedStatus. Only approved accounts can login.');
          }
          
          // Custom user approved, login with nickname
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.login(
            username, 
            storedNickname ?? storedName ?? username, 
            _rememberMe,
            permission: 'user',
            canDelete: true,
          );
          
        } else {
          // Demo account
          final account = demoAccounts[username]!;
          
          // Verify password
          if (account['password'] != password) {
            throw Exception('Incorrect password');
          }
          
          // Check status
          if (account['status'] == 'Pending') {
            setState(() {
              _isLoading = false;
            });
            
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Approval Pending'),
                  content: const Text(
                    'Your account is awaiting administrator approval.\n\n'
                    'Please wait 1-2 days for approval.\n\n'
                    'You will be notified once your account is approved.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
          
          // User is approved, proceed with login
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.login(
            username,
            account['name'] as String,
            _rememberMe,
            permission: account['permissions'] as String?,
            canDelete: account['can_delete_account'] as bool?,
          );
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/campus_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark overlay
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          // Login form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/yonsei_bridge_logo.png',
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Slogan with rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Image.asset(
                          'assets/images/slogan.png',
                          width: 250,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Remember me on this device'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: const Color(0xFF0038A8),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  _showAccountRecoveryDialog();
                                },
                                child: const Text(
                                  '아이디/비밀번호 찾기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
