import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _contactController = TextEditingController();
  XFile? _studentIdImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _nationalityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연세대 학생 인증'),
        content: const Text(
          '학생증이나 재학증명서를 사진촬영하여 주세요.\n\n'
          '사진이 흐리거나 위조가 의심될 시, 가입이 거절당할 수 있습니다.\n\n'
          '⚠️ 중요: 사진은 관리자 승인/거부 즉시 영구 삭제되며, 어떠한 백업도 보관하지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                
                if (image != null) {
                  setState(() {
                    _studentIdImage = image;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('사진 촬영 실패: $e')),
                  );
                }
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _studentIdImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 선택 실패: $e')),
        );
      }
    }
  }

  Future<void> _showPrivacyConsent() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLang = languageService.currentLanguage;
    
    String consentText;
    switch (currentLang) {
      case 'en':
        consentText = '''PRIVACY POLICY CONSENT

By clicking "I Agree", you acknowledge that you have read and understood our Privacy Policy and agree to:

1. Collection of personal information (name, email, nationality, contact, student ID photo)
2. Use of information for account verification and service provision
3. Storage of student ID photo until approval/rejection (then permanently deleted)
4. Processing of your data in accordance with applicable privacy laws

Your student ID photo will be permanently deleted immediately after administrator approval or rejection, with no backups retained.

For full details, please review our Privacy Policy in Settings.''';
        break;
      case 'zh':
        consentText = '''隐私政策同意

点击"我同意"即表示您已阅读并理解我们的隐私政策，并同意：

1. 收集个人信息（姓名、电子邮件、国籍、联系方式、学生证照片）
2. 使用信息进行账户验证和服务提供
3. 存储学生证照片直到批准/拒绝（然后永久删除）
4. 根据适用的隐私法处理您的数据

您的学生证照片将在管理员批准或拒绝后立即永久删除，不保留任何备份。

有关完整详细信息，请查看设置中的隐私政策。''';
        break;
      case 'ja':
        consentText = '''プライバシーポリシーへの同意

「同意する」をクリックすることで、プライバシーポリシーを読んで理解し、以下に同意したことになります：

1. 個人情報の収集（氏名、メール、国籍、連絡先、学生証の写真）
2. アカウント確認とサービス提供のための情報使用
3. 承認/拒否まで学生証写真を保存（その後永久削除）
4. 適用されるプライバシー法に従ったデータ処理

学生証の写真は、管理者による承認または拒否の直後に完全に削除され、バックアップは保持されません。

詳細については、設定でプライバシーポリシーをご確認ください。''';
        break;
      default: // Korean
        consentText = '''개인정보처리방침 동의

"동의합니다"를 클릭하면 개인정보처리방침을 읽고 이해했으며 다음 사항에 동의하는 것으로 간주됩니다:

1. 개인정보 수집 (이름, 이메일, 국적, 연락처, 학생증 사진)
2. 계정 확인 및 서비스 제공을 위한 정보 사용
3. 승인/거부 시까지 학생증 사진 보관 (이후 영구 삭제)
4. 관련 개인정보 보호법에 따른 데이터 처리

학생증 사진은 관리자 승인 또는 거부 즉시 영구적으로 삭제되며, 어떠한 백업도 보관하지 않습니다.

자세한 내용은 설정에서 개인정보처리방침을 확인하세요.''';
    }
    
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(currentLang == 'ko' ? '개인정보처리방침' : 
                     currentLang == 'en' ? 'Privacy Policy' :
                     currentLang == 'zh' ? '隐私政策' : 'プライバシーポリシー'),
        content: SingleChildScrollView(
          child: Text(
            consentText,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(currentLang == 'ko' ? '취소' : 
                       currentLang == 'en' ? 'Cancel' :
                       currentLang == 'zh' ? '取消' : 'キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0038A8),
              foregroundColor: Colors.white,
            ),
            child: Text(currentLang == 'ko' ? '동의합니다' : 
                       currentLang == 'en' ? 'I Agree' :
                       currentLang == 'zh' ? '我同意' : '同意する'),
          ),
        ],
      ),
    );
    
    if (agreed == true) {
      await _submitSignup();
    }
  }

  Future<void> _submitSignup() async {
    if (_formKey.currentState!.validate() && _studentIdImage != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String userId = _usernameController.text.trim();
        
        // For demo purposes without Firebase setup, store locally
        // In production, use actual Firebase Storage and Firestore
        
        // Simulate user registration
        await Future.delayed(const Duration(seconds: 1));
        
        // Store user info locally for demo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('demo_user_$userId', userId);
        await prefs.setString('demo_name_$userId', _nameController.text.trim());
        await prefs.setString('demo_nationality_$userId', _nationalityController.text.trim());
        await prefs.setString('demo_contact_$userId', _contactController.text.trim());
        await prefs.setString('demo_password_$userId', _passwordController.text);
        await prefs.setString('demo_status_$userId', 'Pending');
        
        // Store student ID photo as base64 string for demo
        if (_studentIdImage != null) {
          final bytes = await _studentIdImage!.readAsBytes();
          final base64Image = base64Encode(bytes);
          await prefs.setString('demo_photo_$userId', base64Image);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('회원가입 신청 완료'),
              content: const Text(
                '관리자의 승인이 완료되면 로그인하실 수 있습니다.\n\n'
                '승인까지 1~2일 정도 소요될 수 있습니다.\n\n'
                '⚠️ 학생증 사진은 승인/거부 즉시 자동으로 삭제됩니다.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
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
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원가입 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (_studentIdImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학생증 인증을 완료해주세요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFF0038A8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'YONSEI BRIDGE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0038A8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '연세대학교 미래캠퍼스 유학생 플랫폼',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Step 1: Student ID Verification
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user, color: Color(0xFF0038A8)),
                            SizedBox(width: 8),
                            Text(
                              '1단계: 연세대 학생 인증',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_studentIdImage == null)
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _takePicture,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('학생증 촬영하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0038A8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _pickFromGallery,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('갤러리에서 선택'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: kIsWeb
                                    ? Image.network(_studentIdImage!.path)
                                    : Image.file(File(_studentIdImage!.path)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('다시 촬영하기'),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Step 2: Account Information
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add, color: Color(0xFF0038A8)),
                            SizedBox(width: 8),
                            Text(
                              '2단계: 계정 정보 입력',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '이름',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                            hintText: '실명 입력',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이름을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nationalityController,
                          decoration: const InputDecoration(
                            labelText: '국적',
                            prefixIcon: Icon(Icons.flag),
                            border: OutlineInputBorder(),
                            hintText: '예: Korea, China, Japan',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '국적을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: '연락처',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            hintText: '010-1234-5678 또는 이메일',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '연락처를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: '이메일 주소',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                            hintText: 'example@gmail.com',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            // Email validation
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return '올바른 이메일 형식이 아닙니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '비밀번호',
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
                            hintText: '8자 이상',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            if (value.length < 8) {
                              return '비밀번호는 8자 이상이어야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: '비밀번호 확인',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate() && _studentIdImage != null) {
                        _showPrivacyConsent();
                      } else if (_studentIdImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('학생증 인증을 완료해주세요')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038A8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '가입 신청하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
}
