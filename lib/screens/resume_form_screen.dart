import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class ResumeFormScreen extends StatefulWidget {
  const ResumeFormScreen({super.key});

  @override
  State<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends State<ResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 기본 정보
  final _nameKoreanController = TextEditingController();
  final _nameEnglishController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  
  // 비자 정보
  String _visaType = 'D-2';
  bool _hasARC = false;
  String _workPermitStatus = 'approved';
  final _visaExpiryController = TextEditingController();
  
  // 언어 능력
  String _topikLevel = 'none';
  String _koreanLevel = 'basic';
  final _otherLanguagesController = TextEditingController();
  
  // 근무 희망 조건
  String _workDuration = '6+';
  final _availableTimeController = TextEditingController();
  final List<String> _jobTypes = [];
  final _jobTypeOtherController = TextEditingController();
  
  // 경험
  final _koreaExperienceController = TextEditingController();
  final _homeCountryExperienceController = TextEditingController();
  final _selfIntroController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameKoreanController.dispose();
    _nameEnglishController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalityController.dispose();
    _visaExpiryController.dispose();
    _otherLanguagesController.dispose();
    _availableTimeController.dispose();
    _jobTypeOtherController.dispose();
    _koreaExperienceController.dispose();
    _homeCountryExperienceController.dispose();
    _selfIntroController.dispose();
    super.dispose();
  }

  Map<String, Map<String, String>> _getTranslations() {
    return {
      'ko': {
        'title': '유학생 이력서 작성',
        'section1': '1. 기본 정보 (Personal Info)',
        'name_korean': '이름 (한글)',
        'name_korean_hint': '예: 김영희',
        'name_english': '이름 (영문)',
        'name_english_hint': '여권상 영문명 (예: Kim Young Hee)',
        'phone': '연락처',
        'phone_hint': '010-1234-5678',
        'address': '거주지',
        'address_hint': '예: 원주시 흥업면',
        'nationality': '국적',
        'nationality_hint': '예: 중국, 베트남, 우즈베키스탄 등',
        
        'section2': '2. 비자 및 법적 항목 (Visa & Legal)',
        'visa_warning': '⚠️ 사장님이 안심하고 채용할 수 있도록 정확히 기재해주세요',
        'visa_type': '비자 종류',
        'visa_d2': 'D-2 (유학)',
        'visa_d4': 'D-4 (어학연수)',
        'visa_other': '기타',
        'arc': '외국인 등록증 유무',
        'arc_yes': '외국인 등록증 있음',
        'work_permit': '시간제 취업 허가 여부',
        'work_permit_approved': '허가 완료 (즉시 근무 가능)',
        'work_permit_pending': '채용 시 학교/출입국에 신청 예정',
        'work_permit_tip': '💡 연세브릿지가 절차를 도와드립니다',
        'visa_expiry': '비자 만료일',
        'visa_expiry_hint': '2025-12-31',
        
        'section3': '3. 언어 능력 (Language Skills)',
        'topik': '한국어 능력 (TOPIK)',
        'topik_none': '급수 없음',
        'topik_3': '3급',
        'topik_4': '4급',
        'topik_5plus': '5급 이상',
        'korean_level': '한국어 소통 수준',
        'korean_basic': '기초 (단어 위주 소통 가능)',
        'korean_daily': '일상생활 (주문 및 안내 가능)',
        'korean_fluent': '능숙 (전화 응대 및 복잡한 설명 가능)',
        'other_languages': '기타 언어',
        'other_languages_hint': '예: 영어 능숙, 중국어 모국어',
        
        'section4': '4. 근무 희망 조건 (Work Preferences)',
        'work_duration': '근무 가능 기간',
        'duration_short': '3개월 미만',
        'duration_medium': '3~6개월',
        'duration_long': '6개월 이상 (장기 근무 가능)',
        'available_time': '근무 가능 요일/시간',
        'available_time_hint': '예: 평일 오후 6-10시, 주말 전일',
        'job_types': '희망 직종 (복수 선택 가능)',
        'job_restaurant': '식당 서빙',
        'job_convenience': '편의점/마트',
        'job_office': '사무 보조',
        'job_translation': '통역/번역',
        'job_other': '기타',
        'job_other_hint': '원하는 직종을 입력하세요',
        
        'section5': '5. 경험 및 자기소개 (Experience)',
        'korea_experience': '한국 내 알바 경험',
        'korea_experience_hint': '예: OO식당 서빙 (2024.3~6)',
        'home_experience': '본국에서의 경력',
        'home_experience_hint': '관련 있는 경력 위주로 작성',
        'self_intro': '한 줄 자기소개',
        'self_intro_hint': '예: 성실하고 한국 문화를 좋아합니다!',
        
        'submit': '관리자에게 제출하기',
        'submit_tip': '🔒 제출된 이력서는 관리자만 확인할 수 있습니다',
        'submit_success_title': '제출 완료',
        'submit_success_message': '이력서가 관리자에게 전송되었습니다.\n\n채용 담당자가 검토 후 연락드릴 예정입니다.',
        'confirm': '확인',
        'validation_error': '을(를) 입력해주세요',
      },
      'en': {
        'title': 'International Student Resume',
        'section1': '1. Personal Information',
        'name_korean': 'Name (Korean)',
        'name_korean_hint': 'e.g., 김영희',
        'name_english': 'Name (English)',
        'name_english_hint': 'As on passport (e.g., Kim Young Hee)',
        'phone': 'Phone Number',
        'phone_hint': '010-1234-5678',
        'address': 'Address',
        'address_hint': 'e.g., Heungeop-myeon, Wonju',
        'nationality': 'Nationality',
        'nationality_hint': 'e.g., China, Vietnam, Uzbekistan',
        
        'section2': '2. Visa & Legal Status',
        'visa_warning': '⚠️ Please provide accurate information for employer confidence',
        'visa_type': 'Visa Type',
        'visa_d2': 'D-2 (Student)',
        'visa_d4': 'D-4 (Language)',
        'visa_other': 'Other',
        'arc': 'Alien Registration Card',
        'arc_yes': 'Have ARC',
        'work_permit': 'Part-time Work Permit Status',
        'work_permit_approved': 'Approved (Ready to work)',
        'work_permit_pending': 'Will apply upon employment',
        'work_permit_tip': '💡 Yonsei Bridge will help with the process',
        'visa_expiry': 'Visa Expiry Date',
        'visa_expiry_hint': '2025-12-31',
        
        'section3': '3. Language Skills',
        'topik': 'Korean Proficiency (TOPIK)',
        'topik_none': 'No TOPIK',
        'topik_3': 'Level 3',
        'topik_4': 'Level 4',
        'topik_5plus': 'Level 5+',
        'korean_level': 'Korean Communication Level',
        'korean_basic': 'Basic (Word-based communication)',
        'korean_daily': 'Daily (Can take orders & guide)',
        'korean_fluent': 'Fluent (Phone calls & complex explanations)',
        'other_languages': 'Other Languages',
        'other_languages_hint': 'e.g., Fluent English, Native Chinese',
        
        'section4': '4. Work Preferences',
        'work_duration': 'Available Work Period',
        'duration_short': 'Less than 3 months',
        'duration_medium': '3-6 months',
        'duration_long': '6+ months (Long-term)',
        'available_time': 'Available Days/Hours',
        'available_time_hint': 'e.g., Weekdays 6-10PM, All day weekends',
        'job_types': 'Preferred Jobs (Multiple choice)',
        'job_restaurant': 'Restaurant Server',
        'job_convenience': 'Convenience Store/Mart',
        'job_office': 'Office Assistant',
        'job_translation': 'Translation/Interpretation',
        'job_other': 'Other',
        'job_other_hint': 'Enter desired job type',
        
        'section5': '5. Experience & Introduction',
        'korea_experience': 'Part-time Experience in Korea',
        'korea_experience_hint': 'e.g., Server at XX Restaurant (2024.3~6)',
        'home_experience': 'Work Experience in Home Country',
        'home_experience_hint': 'Focus on relevant experience',
        'self_intro': 'Brief Self-Introduction',
        'self_intro_hint': 'e.g., Hardworking and love Korean culture!',
        
        'submit': 'Submit to Admin',
        'submit_tip': '🔒 Your resume will only be visible to administrators',
        'submit_success_title': 'Submission Complete',
        'submit_success_message': 'Your resume has been sent to the administrator.\n\nThe recruiter will contact you after review.',
        'confirm': 'OK',
        'validation_error': 'Please enter ',
      },
      'zh': {
        'title': '留学生简历填写',
        'section1': '1. 基本信息',
        'name_korean': '姓名 (韩文)',
        'name_korean_hint': '例: 김영희',
        'name_english': '姓名 (英文)',
        'name_english_hint': '护照上的英文名 (例: Kim Young Hee)',
        'phone': '联系方式',
        'phone_hint': '010-1234-5678',
        'address': '居住地',
        'address_hint': '例: 原州市兴业面',
        'nationality': '国籍',
        'nationality_hint': '例: 中国、越南、乌兹别克斯坦等',
        
        'section2': '2. 签证及法律事项',
        'visa_warning': '⚠️ 请准确填写以便雇主放心雇用',
        'visa_type': '签证类型',
        'visa_d2': 'D-2 (留学)',
        'visa_d4': 'D-4 (语言研修)',
        'visa_other': '其他',
        'arc': '外国人登录证',
        'arc_yes': '持有外国人登录证',
        'work_permit': '兼职工作许可状态',
        'work_permit_approved': '已获批准 (可立即工作)',
        'work_permit_pending': '录用时将向学校/出入境申请',
        'work_permit_tip': '💡 延世桥梁将协助办理手续',
        'visa_expiry': '签证到期日',
        'visa_expiry_hint': '2025-12-31',
        
        'section3': '3. 语言能力',
        'topik': '韩语能力 (TOPIK)',
        'topik_none': '无等级',
        'topik_3': '3级',
        'topik_4': '4级',
        'topik_5plus': '5级以上',
        'korean_level': '韩语交流水平',
        'korean_basic': '基础 (可用单词交流)',
        'korean_daily': '日常生活 (可点餐和引导)',
        'korean_fluent': '熟练 (可接听电话和复杂说明)',
        'other_languages': '其他语言',
        'other_languages_hint': '例: 英语熟练，中文母语',
        
        'section4': '4. 工作偏好',
        'work_duration': '可工作期限',
        'duration_short': '3个月以下',
        'duration_medium': '3~6个月',
        'duration_long': '6个月以上 (可长期工作)',
        'available_time': '可工作日期/时间',
        'available_time_hint': '例: 工作日下午6-10点，周末全天',
        'job_types': '期望职位 (可多选)',
        'job_restaurant': '餐厅服务员',
        'job_convenience': '便利店/超市',
        'job_office': '办公室助理',
        'job_translation': '口译/笔译',
        'job_other': '其他',
        'job_other_hint': '输入期望的职位',
        
        'section5': '5. 经验及自我介绍',
        'korea_experience': '韩国境内兼职经验',
        'korea_experience_hint': '例: OO餐厅服务员 (2024.3~6)',
        'home_experience': '本国工作经历',
        'home_experience_hint': '以相关经历为主',
        'self_intro': '一句话自我介绍',
        'self_intro_hint': '例: 认真负责，喜欢韩国文化！',
        
        'submit': '提交给管理员',
        'submit_tip': '🔒 提交的简历仅管理员可见',
        'submit_success_title': '提交完成',
        'submit_success_message': '简历已发送给管理员。\n\n招聘负责人将在审核后与您联系。',
        'confirm': '确认',
        'validation_error': '请输入',
      },
      'ja': {
        'title': '留学生履歴書作成',
        'section1': '1. 基本情報',
        'name_korean': '名前 (韓国語)',
        'name_korean_hint': '例: 김영희',
        'name_english': '名前 (英語)',
        'name_english_hint': 'パスポート上の英語名 (例: Kim Young Hee)',
        'phone': '連絡先',
        'phone_hint': '010-1234-5678',
        'address': '住所',
        'address_hint': '例: 原州市興業面',
        'nationality': '国籍',
        'nationality_hint': '例: 中国、ベトナム、ウズベキスタンなど',
        
        'section2': '2. ビザおよび法的項目',
        'visa_warning': '⚠️ 雇用主が安心して採用できるよう正確に記入してください',
        'visa_type': 'ビザの種類',
        'visa_d2': 'D-2 (留学)',
        'visa_d4': 'D-4 (語学研修)',
        'visa_other': 'その他',
        'arc': '外国人登録証',
        'arc_yes': '外国人登録証あり',
        'work_permit': 'アルバイト許可状況',
        'work_permit_approved': '許可済み (即勤務可能)',
        'work_permit_pending': '採用時に学校/出入国管理事務所に申請予定',
        'work_permit_tip': '💡 延世ブリッジが手続きをサポートします',
        'visa_expiry': 'ビザ有効期限',
        'visa_expiry_hint': '2025-12-31',
        
        'section3': '3. 言語能力',
        'topik': '韓国語能力 (TOPIK)',
        'topik_none': '級なし',
        'topik_3': '3級',
        'topik_4': '4級',
        'topik_5plus': '5級以上',
        'korean_level': '韓国語コミュニケーションレベル',
        'korean_basic': '基礎 (単語中心で意思疎通可能)',
        'korean_daily': '日常生活 (注文・案内可能)',
        'korean_fluent': '流暢 (電話対応・複雑な説明可能)',
        'other_languages': 'その他の言語',
        'other_languages_hint': '例: 英語堪能、中国語母語',
        
        'section4': '4. 勤務希望条件',
        'work_duration': '勤務可能期間',
        'duration_short': '3ヶ月未満',
        'duration_medium': '3~6ヶ月',
        'duration_long': '6ヶ月以上 (長期勤務可能)',
        'available_time': '勤務可能曜日/時間',
        'available_time_hint': '例: 平日午後6-10時、週末終日',
        'job_types': '希望職種 (複数選択可)',
        'job_restaurant': '飲食店接客',
        'job_convenience': 'コンビニ/スーパー',
        'job_office': '事務補助',
        'job_translation': '通訳/翻訳',
        'job_other': 'その他',
        'job_other_hint': '希望する職種を入力',
        
        'section5': '5. 経験および自己紹介',
        'korea_experience': '韓国内アルバイト経験',
        'korea_experience_hint': '例: OO食堂接客 (2024.3~6)',
        'home_experience': '本国での経歴',
        'home_experience_hint': '関連する経歴中心に記入',
        'self_intro': '一言自己紹介',
        'self_intro_hint': '例: 真面目で韓国文化が好きです！',
        
        'submit': '管理者に提出',
        'submit_tip': '🔒 提出した履歴書は管理者のみ確認できます',
        'submit_success_title': '提出完了',
        'submit_success_message': '履歴書が管理者に送信されました。\n\n採用担当者が検討後、連絡いたします。',
        'confirm': '確認',
        'validation_error': 'を入力してください',
      },
    };
  }

  String _getTranslation(String key, String lang) {
    return _getTranslations()[lang]?[key] ?? _getTranslations()['ko']?[key] ?? key;
  }

  Future<void> _submitResume() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate submission
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_getTranslation('submit_success_title', lang)),
            content: Text(_getTranslation('submit_success_message', lang)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(_getTranslation('confirm', lang)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTranslation('title', currentLanguage)),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. 기본 정보
            _buildSectionTitle(_getTranslation('section1', currentLanguage)),
            _buildTextField(
              controller: _nameKoreanController,
              label: _getTranslation('name_korean', currentLanguage),
              hint: _getTranslation('name_korean_hint', currentLanguage),
              required: true,
            ),
            _buildTextField(
              controller: _nameEnglishController,
              label: _getTranslation('name_english', currentLanguage),
              hint: _getTranslation('name_english_hint', currentLanguage),
              required: true,
            ),
            _buildTextField(
              controller: _phoneController,
              label: _getTranslation('phone', currentLanguage),
              hint: _getTranslation('phone_hint', currentLanguage),
              required: true,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _addressController,
              label: _getTranslation('address', currentLanguage),
              hint: _getTranslation('address_hint', currentLanguage),
              required: true,
            ),
            _buildTextField(
              controller: _nationalityController,
              label: _getTranslation('nationality', currentLanguage),
              hint: _getTranslation('nationality_hint', currentLanguage),
              required: true,
            ),
            
            const SizedBox(height: 24),
            
            // 2. 비자 및 법적 항목
            _buildSectionTitle(_getTranslation('section2', currentLanguage)),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _getTranslation('visa_warning', currentLanguage),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            _buildRadioGroup(
              title: _getTranslation('visa_type', currentLanguage),
              value: _visaType,
              options: {
                'D-2': _getTranslation('visa_d2', currentLanguage),
                'D-4': _getTranslation('visa_d4', currentLanguage),
                'other': _getTranslation('visa_other', currentLanguage),
              },
              onChanged: (value) => setState(() => _visaType = value!),
            ),
            _buildCheckbox(
              title: _getTranslation('arc', currentLanguage),
              value: _hasARC,
              onChanged: (value) => setState(() => _hasARC = value!),
              label: _getTranslation('arc_yes', currentLanguage),
            ),
            _buildRadioGroup(
              title: _getTranslation('work_permit', currentLanguage),
              value: _workPermitStatus,
              options: {
                'approved': _getTranslation('work_permit_approved', currentLanguage),
                'pending': _getTranslation('work_permit_pending', currentLanguage),
              },
              onChanged: (value) => setState(() => _workPermitStatus = value!),
            ),
            if (_workPermitStatus == 'pending')
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                child: Text(
                  _getTranslation('work_permit_tip', currentLanguage),
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            _buildTextField(
              controller: _visaExpiryController,
              label: _getTranslation('visa_expiry', currentLanguage),
              hint: _getTranslation('visa_expiry_hint', currentLanguage),
              required: true,
              keyboardType: TextInputType.datetime,
            ),
            
            const SizedBox(height: 24),
            
            // 3. 언어 능력
            _buildSectionTitle(_getTranslation('section3', currentLanguage)),
            _buildRadioGroup(
              title: _getTranslation('topik', currentLanguage),
              value: _topikLevel,
              options: {
                'none': _getTranslation('topik_none', currentLanguage),
                '3': _getTranslation('topik_3', currentLanguage),
                '4': _getTranslation('topik_4', currentLanguage),
                '5+': _getTranslation('topik_5plus', currentLanguage),
              },
              onChanged: (value) => setState(() => _topikLevel = value!),
            ),
            _buildRadioGroup(
              title: _getTranslation('korean_level', currentLanguage),
              value: _koreanLevel,
              options: {
                'basic': _getTranslation('korean_basic', currentLanguage),
                'daily': _getTranslation('korean_daily', currentLanguage),
                'fluent': _getTranslation('korean_fluent', currentLanguage),
              },
              onChanged: (value) => setState(() => _koreanLevel = value!),
            ),
            _buildTextField(
              controller: _otherLanguagesController,
              label: _getTranslation('other_languages', currentLanguage),
              hint: _getTranslation('other_languages_hint', currentLanguage),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // 4. 근무 희망 조건
            _buildSectionTitle(_getTranslation('section4', currentLanguage)),
            _buildRadioGroup(
              title: _getTranslation('work_duration', currentLanguage),
              value: _workDuration,
              options: {
                '<3': _getTranslation('duration_short', currentLanguage),
                '3-6': _getTranslation('duration_medium', currentLanguage),
                '6+': _getTranslation('duration_long', currentLanguage),
              },
              onChanged: (value) => setState(() => _workDuration = value!),
            ),
            _buildTextField(
              controller: _availableTimeController,
              label: _getTranslation('available_time', currentLanguage),
              hint: _getTranslation('available_time_hint', currentLanguage),
              maxLines: 2,
              required: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                _getTranslation('job_types', currentLanguage),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildJobTypeCheckbox('job_restaurant'),
            _buildJobTypeCheckbox('job_convenience'),
            _buildJobTypeCheckbox('job_office'),
            _buildJobTypeCheckbox('job_translation'),
            _buildJobTypeCheckbox('job_other'),
            if (_jobTypes.contains('job_other'))
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                child: _buildTextField(
                  controller: _jobTypeOtherController,
                  label: _getTranslation('job_other', currentLanguage),
                  hint: _getTranslation('job_other_hint', currentLanguage),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // 5. 경험 및 자기소개
            _buildSectionTitle(_getTranslation('section5', currentLanguage)),
            _buildTextField(
              controller: _koreaExperienceController,
              label: _getTranslation('korea_experience', currentLanguage),
              hint: _getTranslation('korea_experience_hint', currentLanguage),
              maxLines: 3,
            ),
            _buildTextField(
              controller: _homeCountryExperienceController,
              label: _getTranslation('home_experience', currentLanguage),
              hint: _getTranslation('home_experience_hint', currentLanguage),
              maxLines: 3,
            ),
            _buildTextField(
              controller: _selfIntroController,
              label: _getTranslation('self_intro', currentLanguage),
              hint: _getTranslation('self_intro_hint', currentLanguage),
              maxLines: 2,
              required: true,
            ),
            
            const SizedBox(height: 32),
            
            // 제출 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _getTranslation('submit', currentLanguage),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Text(
                _getTranslation('submit_tip', currentLanguage),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE91E63),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${_getTranslation('validation_error', lang)} $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildRadioGroup({
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...options.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: value,
              onChanged: onChanged,
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          CheckboxListTile(
            title: Text(label),
            value: value,
            onChanged: onChanged,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeCheckbox(String jobTypeKey) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return CheckboxListTile(
      title: Text(_getTranslation(jobTypeKey, currentLanguage)),
      value: _jobTypes.contains(jobTypeKey),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _jobTypes.add(jobTypeKey);
          } else {
            _jobTypes.remove(jobTypeKey);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
