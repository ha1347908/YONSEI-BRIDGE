import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
    // ── 가입 시 언어 설정 불가 → 항상 영어로 표시 ──────────────────────────
    // Sign-up occurs before language can be set, so always display in English.
    final Map<String, Map<String, String>> privacyContent = {
      'ko': {
        'title': '개인정보 수집·이용 동의',
        'body': '''[Team Yonsei-Bridge](이하 "서비스")는 귀하의 개인정보를 소중히 여기며 개인정보 보호법을 준수합니다. 회원가입 시 동의란에 체크하심으로써 아래와 같이 귀하의 정보 수집 및 이용에 동의하시게 됩니다.

━━━━━━━━━━━━━━━━━━━━━━
1. 수집하는 개인정보 항목

서비스 제공을 위해 아래 최소한의 정보를 수집합니다.

■ 필수 항목
이름, 이메일 주소, 학번, 학생증 사진(인증용), 접속 로그, 쿠키

■ 선택 항목 (광고/마케팅용)
광고 식별자(IDFA/ADID), 서비스 이용 내역, 위치 정보

━━━━━━━━━━━━━━━━━━━━━━
2. 수집·이용 목적

• 본인 인증: 학생증을 통한 신원 확인으로 무단 접근 방지
• 서비스 제공: 정보게시판, 커뮤니티 기능, 다국어 번역 서비스 제공
• 문의 지원: 관리자 연락처를 통한 이용자 요청 및 불만 처리
• 부정 이용 방지: 신원 도용, 서류 위조 등 금지 행위 탐지 및 예방
• 맞춤형 마케팅: 이용자 활동 데이터 기반 맞춤 정보 및 광고 제공

━━━━━━━━━━━━━━━━━━━━━━
3. 보유 및 이용 기간

• 기본 방침: 원칙적으로 이용자가 서비스에서 탈퇴(계정 삭제)할 때까지 개인정보를 보유 및 이용합니다.

• [부정 행위 엄격 예외] 신원 도용 또는 서류 위조로 이용이 종료된 이용자의 정보는 재가입 방지 및 법적 수사 협력을 위해 영구적으로 보유합니다.

━━━━━━━━━━━━━━━━━━━━━━
4. 거부 권리 및 불이익

개인정보 수집·이용을 거부할 권리가 있습니다. 단, 필수 항목은 연세대학교 미래캠퍼스 본인 인증에 필수적이므로 필수 정보 제공을 거부할 경우 회원가입 및 서비스 이용이 불가합니다.

━━━━━━━━━━━━━━━━━━━━━━
5. 맞춤형 광고 및 추적

서비스는 최적화된 콘텐츠 및 광고 제공을 위해 광고 식별자(IDFA)를 수집할 수 있습니다. 기기 설정을 통해 언제든지 추적을 거부할 수 있습니다.

━━━━━━━━━━━━━━━━━━━━━━
부칙 (시행일)
본 약관은 2026년 3월 18일부터 시행됩니다.

문의처
• 이메일: iamharam@yonsei.ac.kr
• 전화: +82 10-2620-4267''',
        'agree': '동의합니다',
        'disagree': '동의하지 않습니다',
        'deny_title': '회원가입 불가',
        'deny_body': '개인정보 수집·이용에 동의하지 않으셨습니다.\n\n필수 항목에 동의하지 않으면 연세브릿지 서비스에 가입하실 수 없습니다.',
        'deny_confirm': '확인',
      },
      'en': {
        'title': 'Personal Information Collection and Usage Agreement',
        'body': '''[Team Yonsei-Bridge] (hereinafter referred to as "the Service") values your personal information and complies with the Personal Information Protection Act. By checking the consent box during registration, you agree to the collection and use of your information as follows:

━━━━━━━━━━━━━━━━━━━━━━
1. Items of Personal Information Collected

The Service collects the following minimum information necessary for providing services:

■ Required Items
Name, Email address, Student ID number, Photo of Student ID (for authentication), Access logs, and Cookies.

■ Optional Items (for Ad/Marketing)
Advertising Identifier (IDFA/ADID), Service usage history, and Location data.

━━━━━━━━━━━━━━━━━━━━━━
2. Purpose of Collection and Use

• User Authentication: Verifying identity through student ID to prevent unauthorized access.
• Service Provision: Providing information boards, community features, and multilingual translation services.
• Inquiry Support: Responding to user requests and complaints via the administrator contact.
• Prevention of Misuse: Detecting and preventing identity theft, document forgery, and other prohibited activities.
• Personalized Marketing: Providing customized information and advertisements based on user activity data.

━━━━━━━━━━━━━━━━━━━━━━
3. Retention and Usage Period

• Standard Policy: In principle, personal information is retained and used until the user withdraws from the service (account deletion).

• [Strict Exception for Fraud]: Information regarding users terminated for identity theft or document forgery will be permanently retained to prevent re-registration and to cooperate with legal investigations.

━━━━━━━━━━━━━━━━━━━━━━
4. Right to Refuse and Consequences

You have the right to refuse the collection and use of your personal information. However, since the required items are essential for identity verification at Yonsei University Mirae Campus, refusal to provide required information will result in the inability to sign up or use the service.

━━━━━━━━━━━━━━━━━━━━━━
5. Personalized Advertisements and Tracking

The Service may collect advertising identifiers (IDFA) to provide optimized content and ads. You may opt-out of this tracking at any time through your device settings.

━━━━━━━━━━━━━━━━━━━━━━
Addendum (Effective Date)
These terms shall take effect as of March 18, 2026.

Contact Information
• Email: iamharam@yonsei.ac.kr
• Phone: +82 10-2620-4267''',
        'agree': 'I Agree',
        'disagree': 'I Disagree',
        'deny_title': 'Registration Not Available',
        'deny_body': 'You have not agreed to the collection and use of personal information.\n\nWithout consent to the required items, you cannot sign up for the YONSEI BRIDGE service.',
        'deny_confirm': 'OK',
      },
      'zh': {
        'title': '个人信息收集与使用同意',
        'body': '''[Team Yonsei-Bridge]（以下简称"服务"）重视您的个人信息，并遵守个人信息保护法。在注册时勾选同意框，即表示您同意按如下方式收集和使用您的信息：

━━━━━━━━━━━━━━━━━━━━━━
1. 收集的个人信息项目

服务收集以下提供服务所需的最少信息：

■ 必填项目
姓名、电子邮件地址、学号、学生证照片（用于认证）、访问日志及Cookie。

■ 选填项目（广告/营销用）
广告标识符（IDFA/ADID）、服务使用记录、位置数据。

━━━━━━━━━━━━━━━━━━━━━━
2. 收集与使用目的

• 用户认证：通过学生证验证身份，防止未经授权的访问。
• 服务提供：提供信息板、社区功能及多语言翻译服务。
• 咨询支持：通过管理员联系方式响应用户请求和投诉。
• 防止滥用：检测并防止身份盗用、文件伪造及其他违禁行为。
• 个性化营销：根据用户活动数据提供定制信息和广告。

━━━━━━━━━━━━━━━━━━━━━━
3. 保留与使用期限

• 基本方针：原则上，个人信息保留至用户退出服务（删除账户）为止。

• [严格的欺诈例外规定]：因身份盗用或文件伪造而被终止服务的用户信息，将被永久保留，以防止重新注册并配合法律调查。

━━━━━━━━━━━━━━━━━━━━━━
4. 拒绝权利及后果

您有权拒绝收集和使用您的个人信息。但是，由于必填项目是延世大学未来校区身份验证的必要条件，拒绝提供必填信息将导致无法注册或使用服务。

━━━━━━━━━━━━━━━━━━━━━━
5. 个性化广告与追踪

服务可能会收集广告标识符（IDFA）以提供优化的内容和广告。您可以随时通过设备设置选择退出追踪。

━━━━━━━━━━━━━━━━━━━━━━
附则（生效日期）
本条款自2026年3月18日起生效。

联系方式
• 电子邮件：iamharam@yonsei.ac.kr
• 电话：+82 10-2620-4267''',
        'agree': '我同意',
        'disagree': '我不同意',
        'deny_title': '无法注册',
        'deny_body': '您尚未同意收集和使用个人信息。\n\n如不同意必填项目，则无法注册延世桥服务。',
        'deny_confirm': '确认',
      },
      'ja': {
        'title': '個人情報収集・利用同意',
        'body': '''[Team Yonsei-Bridge]（以下「サービス」）はお客様の個人情報を大切にし、個人情報保護法を遵守します。会員登録時に同意欄にチェックすることで、以下のとおり情報の収集・利用に同意したものとみなされます。

━━━━━━━━━━━━━━━━━━━━━━
1. 収集する個人情報の項目

サービス提供に必要な最小限の情報を収集します。

■ 必須項目
氏名、メールアドレス、学籍番号、学生証写真（認証用）、アクセスログ、Cookie

■ 任意項目（広告・マーケティング用）
広告識別子（IDFA/ADID）、サービス利用履歴、位置情報

━━━━━━━━━━━━━━━━━━━━━━
2. 収集・利用目的

• 本人確認：学生証による身元確認で不正アクセスを防止
• サービス提供：情報掲示板、コミュニティ機能、多言語翻訳サービスの提供
• お問い合わせ対応：管理者連絡先を通じたユーザーリクエスト・苦情への対応
• 不正利用防止：なりすまし、書類偽造その他禁止行為の検出・防止
• パーソナライズドマーケティング：ユーザー活動データに基づくカスタマイズ情報・広告の提供

━━━━━━━━━━━━━━━━━━━━━━
3. 保有・利用期間

• 基本方針：原則として、ユーザーがサービスを退会（アカウント削除）するまで個人情報を保有・利用します。

• [不正行為に関する厳格な例外]：なりすましまたは書類偽造により利用が停止されたユーザーの情報は、再登録防止および法的捜査への協力のため永久に保有します。

━━━━━━━━━━━━━━━━━━━━━━
4. 拒否権と不利益

個人情報の収集・利用を拒否する権利があります。ただし、必須項目は延世大学ミレキャンパスにおける本人確認に不可欠なため、必須情報の提供を拒否した場合は会員登録およびサービスの利用ができません。

━━━━━━━━━━━━━━━━━━━━━━
5. パーソナライズド広告とトラッキング

サービスは最適化されたコンテンツおよび広告提供のため、広告識別子（IDFA）を収集する場合があります。端末の設定からいつでもトラッキングを拒否できます。

━━━━━━━━━━━━━━━━━━━━━━
附則（施行日）
本規約は2026年3月18日より施行されます。

お問い合わせ先
• メール：iamharam@yonsei.ac.kr
• 電話：+82 10-2620-4267''',
        'agree': '同意する',
        'disagree': '同意しない',
        'deny_title': '会員登録不可',
        'deny_body': '個人情報の収集・利用にご同意いただけませんでした。\n\n必須項目への同意がない場合、YONSEI BRIDGEサービスへの登録はできません。',
        'deny_confirm': '確認',
      },
    };

    // 항상 영어로 고정 (Always fixed to English)
    final lang = privacyContent['en']!;

    // ── 개인정보 동의 팝업 표시 ────────────────────────────────────────────
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0038A8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 본문 (스크롤)
            SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.55,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  lang['body']!,
                  style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF222222)),
                ),
              ),
            ),
            // 구분선
            const Divider(height: 1),
            // 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        lang['disagree']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0038A8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        lang['agree']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (agreed == true) {
      await _submitSignup();
    } else {
      // ── 동의 거부 시 안내 팝업 ────────────────────────────────────────────
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red[600], size: 22),
                const SizedBox(width: 8),
                Text(
                  lang['deny_title']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            content: Text(
              lang['deny_body']!,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(lang['deny_confirm']!),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _submitSignup() async {
    // validate() 재호출 제거 — Privacy Consent 진입 전 이미 통과된 상태
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // 사진을 base64로 인코딩
      String? photoBase64;
      if (_studentIdImage != null) {
        try {
          final bytes = await _studentIdImage!.readAsBytes();
          photoBase64 = base64Encode(bytes);
        } catch (e) {
          debugPrint('Photo encoding error: $e');
        }
      }

      await authService.signUp(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        nationality: _selectedNationality ?? 'Unknown',
        contact: _contactController.text.trim(),
        idPhotoBase64: photoBase64,
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
