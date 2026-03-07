import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../widgets/country_search_dropdown.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(); // stores email
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _selectedNationality;
  final _contactController = TextEditingController();
  XFile? _studentIdImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _departmentSearchController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _contactController.dispose();
    _departmentSearchController.dispose();
    super.dispose();
    // _selectedCampus and _selectedDepartment reserved for future use
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yonsei Student Verification'),
        content: const Text(
          'Please take a photo of your student ID or enrollment certificate.\n\n'
          'Blurry or suspected forged photos may result in registration rejection.\n\n'
          '⚠️ Important: The photo will be permanently deleted immediately after '
          'administrator approval or rejection — no backup is retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                    SnackBar(content: Text('Camera error: $e')),
                  );
                }
              }
            },
            child: const Text('OK'),
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
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _showPrivacyConsent() async {
    final languageService =
        Provider.of<LanguageService>(context, listen: false);
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
        title: Text(currentLang == 'ko'
            ? '개인정보처리방침'
            : currentLang == 'en'
                ? 'Privacy Policy'
                : currentLang == 'zh'
                    ? '隐私政策'
                    : 'プライバシーポリシー'),
        content: SingleChildScrollView(
          child: Text(
            consentText,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(currentLang == 'ko'
                ? '취소'
                : currentLang == 'en'
                    ? 'Cancel'
                    : currentLang == 'zh'
                        ? '取消'
                        : 'キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0038A8),
              foregroundColor: Colors.white,
            ),
            child: Text(currentLang == 'ko'
                ? '동의합니다'
                : currentLang == 'en'
                    ? 'I Agree'
                    : currentLang == 'zh'
                        ? '我同意'
                        : '同意する'),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await _submitSignup();
    }
  }

  Future<void> _submitSignup() async {
    // validate() 재호출 제거 — Privacy Consent 진입 전 이미 통과된 상태
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signUp(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        nationality: _selectedNationality ?? 'Unknown',
        contact: _contactController.text.trim(),
      );

        setState(() => _isLoading = false);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Sign-Up Application Submitted'),
              content: const Text(
                'Your account has been created and is awaiting administrator approval.\n\n'
                'Approval may take 1–2 business days.\n\n'
                '⚠️ Your student ID photo will be automatically deleted upon approval or rejection.',
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
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
                  'International Student Platform — Yonsei University Mirae Campus',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
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
                            Icon(Icons.verified_user,
                                color: Color(0xFF0038A8)),
                            SizedBox(width: 8),
                            Text(
                              'Step 1: Yonsei Student Verification',
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
                                label: const Text('Take Photo of Student ID'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF0038A8),
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
                                icon:
                                    const Icon(Icons.photo_library),
                                label:
                                    const Text('Choose from Gallery'),
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
                                  border:
                                      Border.all(color: Colors.grey),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: kIsWeb
                                    ? Image.network(
                                        _studentIdImage!.path)
                                    : Image.file(
                                        File(_studentIdImage!.path)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _takePicture,
                                    icon:
                                        const Icon(Icons.refresh),
                                    label:
                                        const Text('Retake Photo'),
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
                            Icon(Icons.person_add,
                                color: Color(0xFF0038A8)),
                            SizedBox(width: 8),
                            Text(
                              'Step 2: Account Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name (Real Name)',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 홍길동, John Smith',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Nickname
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: 'Nickname (Display Name)',
                            prefixIcon:
                                Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                            hintText:
                                'Nickname shown inside the app',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a nickname';
                            }
                            if (value.length < 2) {
                              return 'Nickname must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Nationality
                        CountrySearchDropdown(
                          initialValue: _selectedNationality,
                          hintText:
                              'Nationality / Country of Origin',
                          onCountrySelected: (country) {
                            setState(
                                () => _selectedNationality = country);
                          },
                        ),
                        if (_selectedNationality == null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12, top: 4),
                            child: Text(
                              'Please select your nationality',
                              style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Contact
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact (Phone / Email)',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            hintText:
                                '010-1234-5678 or email address',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your contact information';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email (used as login ID)
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address (Login ID)',
                            prefixIcon:
                                Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                            hintText: 'example@gmail.com',
                            helperText:
                                'This email address will be used as your login ID',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                            hintText: 'At least 8 characters',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_studentIdImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please complete student ID verification')),
                              );
                              return;
                            }
                            if (_selectedNationality == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select your nationality')),
                              );
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              _showPrivacyConsent();
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
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text(
                            'Submit Application',
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
