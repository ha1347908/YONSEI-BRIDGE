import 'package:flutter/material.dart';

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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('제출 완료'),
            content: const Text(
              '이력서가 관리자에게 전송되었습니다.\n\n'
              '채용 담당자가 검토 후 연락드릴 예정입니다.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('유학생 이력서 작성'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. 기본 정보
            _buildSectionTitle('1. 기본 정보 (Personal Info)'),
            _buildTextField(
              controller: _nameKoreanController,
              label: '이름 (한글)',
              hint: '예: 김영희',
              required: true,
            ),
            _buildTextField(
              controller: _nameEnglishController,
              label: '이름 (영문)',
              hint: '여권상 영문명 (예: Kim Young Hee)',
              required: true,
            ),
            _buildTextField(
              controller: _phoneController,
              label: '연락처',
              hint: '010-1234-5678',
              required: true,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _addressController,
              label: '거주지',
              hint: '예: 원주시 흥업면',
              required: true,
            ),
            _buildTextField(
              controller: _nationalityController,
              label: '국적',
              hint: '예: 중국, 베트남, 우즈베키스탄 등',
              required: true,
            ),
            
            const SizedBox(height: 24),
            
            // 2. 비자 및 법적 항목
            _buildSectionTitle('2. 비자 및 법적 항목 (Visa & Legal)'),
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                '⚠️ 사장님이 안심하고 채용할 수 있도록 정확히 기재해주세요',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            _buildRadioGroup(
              title: '비자 종류',
              value: _visaType,
              options: const {
                'D-2': 'D-2 (유학)',
                'D-4': 'D-4 (어학연수)',
                'other': '기타',
              },
              onChanged: (value) => setState(() => _visaType = value!),
            ),
            _buildCheckbox(
              title: '외국인 등록증 유무',
              value: _hasARC,
              onChanged: (value) => setState(() => _hasARC = value!),
              label: '외국인 등록증 있음',
            ),
            _buildRadioGroup(
              title: '시간제 취업 허가 여부',
              value: _workPermitStatus,
              options: const {
                'approved': '허가 완료 (즉시 근무 가능)',
                'pending': '채용 시 학교/출입국에 신청 예정',
              },
              onChanged: (value) => setState(() => _workPermitStatus = value!),
            ),
            if (_workPermitStatus == 'pending')
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                child: Text(
                  '💡 연세브릿지가 절차를 도와드립니다',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            _buildTextField(
              controller: _visaExpiryController,
              label: '비자 만료일',
              hint: '2025-12-31',
              required: true,
              keyboardType: TextInputType.datetime,
            ),
            
            const SizedBox(height: 24),
            
            // 3. 언어 능력
            _buildSectionTitle('3. 언어 능력 (Language Skills)'),
            _buildRadioGroup(
              title: '한국어 능력 (TOPIK)',
              value: _topikLevel,
              options: const {
                'none': '급수 없음',
                '3': '3급',
                '4': '4급',
                '5+': '5급 이상',
              },
              onChanged: (value) => setState(() => _topikLevel = value!),
            ),
            _buildRadioGroup(
              title: '한국어 소통 수준',
              value: _koreanLevel,
              options: const {
                'basic': '기초 (단어 위주 소통 가능)',
                'daily': '일상생활 (주문 및 안내 가능)',
                'fluent': '능숙 (전화 응대 및 복잡한 설명 가능)',
              },
              onChanged: (value) => setState(() => _koreanLevel = value!),
            ),
            _buildTextField(
              controller: _otherLanguagesController,
              label: '기타 언어',
              hint: '예: 영어 능숙, 중국어 모국어',
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // 4. 근무 희망 조건
            _buildSectionTitle('4. 근무 희망 조건 (Work Preferences)'),
            _buildRadioGroup(
              title: '근무 가능 기간',
              value: _workDuration,
              options: const {
                '<3': '3개월 미만',
                '3-6': '3~6개월',
                '6+': '6개월 이상 (장기 근무 가능)',
              },
              onChanged: (value) => setState(() => _workDuration = value!),
            ),
            _buildTextField(
              controller: _availableTimeController,
              label: '근무 가능 요일/시간',
              hint: '예: 평일 오후 6-10시, 주말 전일',
              maxLines: 2,
              required: true,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                '희망 직종 (복수 선택 가능)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildJobTypeCheckbox('식당 서빙'),
            _buildJobTypeCheckbox('편의점/마트'),
            _buildJobTypeCheckbox('사무 보조'),
            _buildJobTypeCheckbox('통역/번역'),
            _buildJobTypeCheckbox('기타'),
            if (_jobTypes.contains('기타'))
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                child: _buildTextField(
                  controller: _jobTypeOtherController,
                  label: '기타 직종',
                  hint: '원하는 직종을 입력하세요',
                ),
              ),
            
            const SizedBox(height: 24),
            
            // 5. 경험 및 자기소개
            _buildSectionTitle('5. 경험 및 자기소개 (Experience)'),
            _buildTextField(
              controller: _koreaExperienceController,
              label: '한국 내 알바 경험',
              hint: '예: OO식당 서빙 (2024.3~6)',
              maxLines: 3,
            ),
            _buildTextField(
              controller: _homeCountryExperienceController,
              label: '본국에서의 경력',
              hint: '관련 있는 경력 위주로 작성',
              maxLines: 3,
            ),
            _buildTextField(
              controller: _selfIntroController,
              label: '한 줄 자기소개',
              hint: '예: 성실하고 한국 문화를 좋아합니다!',
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
                    : const Text(
                        '관리자에게 제출하기',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '🔒 제출된 이력서는 관리자만 확인할 수 있습니다',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  return '$label을(를) 입력해주세요';
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

  Widget _buildJobTypeCheckbox(String jobType) {
    return CheckboxListTile(
      title: Text(jobType),
      value: _jobTypes.contains(jobType),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _jobTypes.add(jobType);
          } else {
            _jobTypes.remove(jobType);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
