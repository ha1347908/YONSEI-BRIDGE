import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';

class SymptomCardScreen extends StatefulWidget {
  const SymptomCardScreen({super.key});

  @override
  State<SymptomCardScreen> createState() => _SymptomCardScreenState();
}

class _SymptomCardScreenState extends State<SymptomCardScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 기본 정보
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  
  // 방문 목적
  final List<String> _painAreas = [];
  final _painAreaOtherController = TextEditingController();
  String _symptomStart = 'today';
  double _painLevel = 5.0;
  
  // 상세 증상
  final List<String> _respiratorySymptoms = [];
  final List<String> _digestiveSymptoms = [];
  final List<String> _painSymptoms = [];
  
  // 과거력
  bool _takingMedicine = false;
  final _medicineController = TextEditingController();
  bool _hasAllergy = false;
  final _allergyController = TextEditingController();
  bool? _pregnant;
  
  // 협조 요청
  final List<String> _specialRequests = [];
  
  @override
  void dispose() {
    _nameController.dispose();
    _painAreaOtherController.dispose();
    _medicineController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    if (_formKey.currentState!.validate()) {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      final currentLanguage = languageService.currentLanguage;
      
      // Load Korean font
      final fontData = await rootBundle.load('fonts/NotoSansKR-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);
      
      final pdf = pw.Document();
      
      String getTranslation(String key, String lang) {
        return _getTranslations()[lang]?[key] ?? 
               _getTranslations()['ko']?[key] ?? key;
      }
      
      // Helper function to create bilingual text (User Language | Korean)
      String getBilingualText(String key) {
        if (currentLanguage == 'ko') {
          return getTranslation(key, 'ko');
        } else {
          return '${getTranslation(key, currentLanguage)} | ${getTranslation(key, 'ko')}';
        }
      }
      
      // PDF 생성
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttf,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  getBilingualText('title'),
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue),
                  ),
                  child: pw.Text(
                    getBilingualText('doctor_instruction'),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: ttf),
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 12),
                
                // 기본 정보
                _buildPDFSection(getBilingualText('basic_info'), ttf),
                _buildPDFRow(getBilingualText('name'), _nameController.text, ttf),
                _buildPDFRow(getBilingualText('birth_date'), 
                  _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : '', ttf),
                _buildPDFRow(getBilingualText('gender'), 
                  getBilingualText(_gender == 'male' ? 'male' : 'female'), ttf),
                pw.SizedBox(height: 10),
                
                // 방문 목적
                _buildPDFSection(getBilingualText('purpose'), ttf),
                _buildPDFRow(getBilingualText('pain_areas'), 
                  _painAreas.map((e) => getBilingualText(e)).join(', '), ttf),
                if (_painAreas.contains('other') && _painAreaOtherController.text.isNotEmpty)
                  _buildPDFRow(getBilingualText('other'), _painAreaOtherController.text, ttf),
                _buildPDFRow(getBilingualText('symptom_start'), getBilingualText(_symptomStart), ttf),
                _buildPDFRow(getBilingualText('pain_level'), '${_painLevel.toInt()}/10', ttf),
                pw.SizedBox(height: 10),
                
                // 상세 증상
                _buildPDFSection(getBilingualText('symptoms'), ttf),
                if (_respiratorySymptoms.isNotEmpty)
                  _buildPDFRow(getBilingualText('respiratory'), 
                    _respiratorySymptoms.map((e) => getBilingualText(e)).join(', '), ttf),
                if (_digestiveSymptoms.isNotEmpty)
                  _buildPDFRow(getBilingualText('digestive'), 
                    _digestiveSymptoms.map((e) => getBilingualText(e)).join(', '), ttf),
                if (_painSymptoms.isNotEmpty)
                  _buildPDFRow(getBilingualText('pain_other'), 
                    _painSymptoms.map((e) => getBilingualText(e)).join(', '), ttf),
                pw.SizedBox(height: 10),
                
                // 과거력
                _buildPDFSection(getBilingualText('medical_history'), ttf),
                _buildPDFRow(getBilingualText('taking_medicine'), 
                  _takingMedicine ? (_medicineController.text.isNotEmpty ? _medicineController.text : getBilingualText('yes')) : getBilingualText('no'), ttf),
                _buildPDFRow(getBilingualText('has_allergy'), 
                  _hasAllergy ? (_allergyController.text.isNotEmpty ? _allergyController.text : getBilingualText('yes')) : getBilingualText('no'), ttf),
                if (_gender == 'female' && _pregnant != null)
                  _buildPDFRow(getBilingualText('pregnant'), _pregnant! ? getBilingualText('yes') : getBilingualText('no'), ttf),
                pw.SizedBox(height: 10),
                
                // 협조 요청
                if (_specialRequests.isNotEmpty) ...[
                  _buildPDFSection(getBilingualText('special_requests'), ttf),
                  pw.Text(
                    _specialRequests.map((e) => '• ${getBilingualText(e)}').join('\n'),
                    style: pw.TextStyle(font: ttf, fontSize: 10),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // PDF 저장/공유
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  pw.Widget _buildPDFSection(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: font),
      ),
    );
  }

  pw.Widget _buildPDFRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 180,
            child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 10)),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10))),
        ],
      ),
    );
  }

  Map<String, Map<String, String>> _getTranslations() {
    return {
      'ko': {
        'title': '연세브릿지 안심진료 증상카드',
        'doctor_instruction': '👨‍⚕️ 의사 선생님께 이 화면을 보여주세요',
        'basic_info': '1. 기본 정보',
        'name': '성함',
        'birth_date': '생년월일',
        'gender': '성별',
        'male': '남성',
        'female': '여성',
        'purpose': '2. 방문 목적 및 시기',
        'pain_areas': '아픈 부위',
        'head': '머리',
        'throat': '목(인후)',
        'chest': '가슴',
        'stomach': '배(복부)',
        'limbs': '팔/다리',
        'skin': '피부',
        'other': '기타',
        'symptom_start': '증상 시작 시기',
        'today': '오늘',
        'yesterday': '어제',
        '2-3days': '2~3일 전',
        '1week': '1주일 전',
        '1month+': '1개월 이상 전',
        'pain_level': '통증 정도',
        'symptoms': '3. 상세 증상',
        'respiratory': '전신/호흡기',
        'fever': '발열/열남',
        'chills': '오한',
        'cough': '기침',
        'runny_nose': '콧물',
        'phlegm': '가래',
        'sore_throat': '목 아픔',
        'digestive': '소화기',
        'abdominal_pain': '복통',
        'heartburn': '속쓰림',
        'nausea': '구토/메스꺼움',
        'diarrhea': '설사',
        'constipation': '변비',
        'pain_other': '통증/기타',
        'headache': '두통',
        'dizziness': '어지러움',
        'muscle_pain': '근육통',
        'itching': '가려움/발진',
        'menstrual_pain': '생리통',
        'medical_history': '4. 과거력 및 알레르기',
        'taking_medicine': '복용 중인 약',
        'has_allergy': '알레르기',
        'pregnant': '임신 가능성',
        'yes': '있음',
        'no': '없음',
        'special_requests': '5. 협조 요청',
        'speak_slowly': '한국어를 천천히 말씀해 주세요',
        'explain_english': '의학 용어는 영어로도 설명해 주세요',
        'use_translator': '번역기(앱)를 사용하여 소통하고 싶습니다',
        'write_instructions': '처방전이나 주의사항을 메모(글자)로 적어주세요',
        'save_pdf': 'PDF로 저장하기',
        'pdf_tip': '💡 PDF를 병원에 가져가서 의사 선생님께 보여주세요',
        'current_language': '현재 언어',
        'change_language_tip': '설정에서 언어를 변경할 수 있습니다.',
      },
      'en': {
        'title': 'Yonsei Bridge Medical Symptom Card',
        'doctor_instruction': '👨‍⚕️ Please show this to your doctor',
        'basic_info': '1. Basic Information',
        'name': 'Name',
        'birth_date': 'Date of Birth',
        'gender': 'Gender',
        'male': 'Male',
        'female': 'Female',
        'purpose': '2. Purpose & Timing',
        'pain_areas': 'Pain Areas',
        'head': 'Head',
        'throat': 'Throat',
        'chest': 'Chest',
        'stomach': 'Stomach',
        'limbs': 'Arms/Legs',
        'skin': 'Skin',
        'other': 'Others',
        'symptom_start': 'Symptom Start',
        'today': 'Today',
        'yesterday': 'Yesterday',
        '2-3days': '2-3 days ago',
        '1week': '1 week ago',
        '1month+': 'More than a month ago',
        'pain_level': 'Pain Level',
        'symptoms': '3. Symptom Checklist',
        'respiratory': 'General/Respiratory',
        'fever': 'Fever',
        'chills': 'Chills',
        'cough': 'Cough',
        'runny_nose': 'Runny nose',
        'phlegm': 'Phlegm',
        'sore_throat': 'Sore throat',
        'digestive': 'Digestive',
        'abdominal_pain': 'Stomachache',
        'heartburn': 'Heartburn',
        'nausea': 'Nausea/Vomiting',
        'diarrhea': 'Diarrhea',
        'constipation': 'Constipation',
        'pain_other': 'Pain/Others',
        'headache': 'Headache',
        'dizziness': 'Dizziness',
        'muscle_pain': 'Muscle pain',
        'itching': 'Itching/Rash',
        'menstrual_pain': 'Menstrual cramps',
        'medical_history': '4. Medical History & Allergy',
        'taking_medicine': 'Current Medication',
        'has_allergy': 'Allergies',
        'pregnant': 'Pregnancy Possibility',
        'yes': 'Yes',
        'no': 'No',
        'special_requests': '5. Special Requests',
        'speak_slowly': 'Please speak Korean slowly',
        'explain_english': 'Please explain medical terms in English',
        'use_translator': "I'd like to use a translator app",
        'write_instructions': 'Please write down the instructions',
        'save_pdf': 'Save as PDF',
        'pdf_tip': '💡 Take this PDF to the hospital and show it to your doctor',
        'current_language': 'Current Language',
        'change_language_tip': 'You can change the language in Settings.',
      },
      'zh': {
        'title': '延世桥梁 安心诊疗症状卡',
        'doctor_instruction': '👨‍⚕️ 请将此卡片出示给医生',
        'basic_info': '1. 基本信息',
        'name': '姓名',
        'birth_date': '出生日期',
        'gender': '性别',
        'male': '男',
        'female': '女',
        'purpose': '2. 就诊目的及时间',
        'pain_areas': '疼痛部位',
        'head': '头部',
        'throat': '咽喉',
        'chest': '胸部',
        'stomach': '腹部',
        'limbs': '胳膊/腿',
        'skin': '皮肤',
        'other': '其他',
        'symptom_start': '症状开始时间',
        'today': '今天',
        'yesterday': '昨天',
        '2-3days': '2-3天前',
        '1week': '1周前',
        '1month+': '1个月以上前',
        'pain_level': '疼痛程度',
        'symptoms': '3. 详细症状清单',
        'respiratory': '全身/呼吸系统',
        'fever': '发烧',
        'chills': '发冷',
        'cough': '咳嗽',
        'runny_nose': '流鼻涕',
        'phlegm': '有痰',
        'sore_throat': '咽喉痛',
        'digestive': '消化系统',
        'abdominal_pain': '腹痛',
        'heartburn': '烧心',
        'nausea': '恶心/呕吐',
        'diarrhea': '腹泻',
        'constipation': '便秘',
        'pain_other': '疼痛/其他',
        'headache': '头痛',
        'dizziness': '头晕',
        'muscle_pain': '肌肉痛',
        'itching': '瘙痒/皮疹',
        'menstrual_pain': '生理痛',
        'medical_history': '4. 过往病史及过敏',
        'taking_medicine': '正在服用的药物',
        'has_allergy': '过敏史',
        'pregnant': '怀孕可能',
        'yes': '有',
        'no': '无',
        'special_requests': '5. 协作请求',
        'speak_slowly': '请放慢韩语说话速度',
        'explain_english': '请用英语解释医学术语',
        'use_translator': '我想通过翻译软件进行沟通',
        'write_instructions': '请将注意事项以文字形式写下来',
        'save_pdf': '保存为PDF',
        'pdf_tip': '💡 请将此PDF带到医院给医生查看',
        'current_language': '当前语言',
        'change_language_tip': '您可以在设置中更改语言。',
      },
      'ja': {
        'title': '延世ブリッジ 安心診療症状カード',
        'doctor_instruction': '👨‍⚕️ このカードを医師にお見せください',
        'basic_info': '1. 基本情報',
        'name': 'お名前',
        'birth_date': '生年月日',
        'gender': '性別',
        'male': '男性',
        'female': '女性',
        'purpose': '2. 受診目的と時期',
        'pain_areas': '痛む部位',
        'head': '頭',
        'throat': '喉',
        'chest': '胸',
        'stomach': 'お腹(腹部)',
        'limbs': '腕/足',
        'skin': '皮膚',
        'other': 'その他',
        'symptom_start': '症状開始時期',
        'today': '今日',
        'yesterday': '昨日',
        '2-3days': '2~3日前',
        '1week': '1週間前',
        '1month+': '1ヶ月以上前',
        'pain_level': '痛みの強さ',
        'symptoms': '3. 詳細症状チェックリスト',
        'respiratory': '全身/呼吸器',
        'fever': '発熱',
        'chills': '悪寒',
        'cough': '咳',
        'runny_nose': '鼻水',
        'phlegm': '痰',
        'sore_throat': '喉の痛み',
        'digestive': '消化器',
        'abdominal_pain': '腹痛',
        'heartburn': '胸焼け',
        'nausea': '吐き気/嘔吐',
        'diarrhea': '下痢',
        'constipation': '便秘',
        'pain_other': '痛み/その他',
        'headache': '頭痛',
        'dizziness': 'めまい',
        'muscle_pain': '筋肉痛',
        'itching': 'かゆみ/発疹',
        'menstrual_pain': '生理痛',
        'medical_history': '4. 既往歴およびアレルギー',
        'taking_medicine': '服用中の薬',
        'has_allergy': 'アレルギー',
        'pregnant': '妊娠の可能性',
        'yes': 'あり',
        'no': 'なし',
        'special_requests': '5. 協力要請',
        'speak_slowly': '韓国語をゆっくり話してください',
        'explain_english': '医学用語は英語でも説明してください',
        'use_translator': '翻訳アプリを使って意思疎通をしたいです',
        'write_instructions': '注意事項をメモ(文字)で書いてください',
        'save_pdf': 'PDFとして保存',
        'pdf_tip': '💡 このPDFを病院に持って行き、医師にお見せください',
        'current_language': '現在の言語',
        'change_language_tip': '設定で言語を変更できます。',
      },
    };
  }

  String _getTranslation(String key, String lang) {
    return _getTranslations()[lang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTranslation('title', currentLanguage)),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 언어 정보 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_getTranslation('current_language', currentLanguage)}: ${_getLanguageName(currentLanguage)}\n${_getTranslation('change_language_tip', currentLanguage)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 1. 기본 정보
            _buildSectionTitle(_getTranslation('basic_info', currentLanguage)),
            _buildTextField(
              controller: _nameController,
              label: _getTranslation('name', currentLanguage),
              required: true,
            ),
            _buildDatePicker(),
            _buildRadioGroup(
              title: _getTranslation('gender', currentLanguage),
              value: _gender,
              options: {
                'male': _getTranslation('male', currentLanguage),
                'female': _getTranslation('female', currentLanguage),
              },
              onChanged: (value) => setState(() => _gender = value!),
            ),
            
            const SizedBox(height: 24),
            
            // 2. 방문 목적
            _buildSectionTitle(_getTranslation('purpose', currentLanguage)),
            Text(_getTranslation('pain_areas', currentLanguage), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildPainAreaCheckbox('head'),
            _buildPainAreaCheckbox('throat'),
            _buildPainAreaCheckbox('chest'),
            _buildPainAreaCheckbox('stomach'),
            _buildPainAreaCheckbox('limbs'),
            _buildPainAreaCheckbox('skin'),
            _buildPainAreaCheckbox('other'),
            if (_painAreas.contains('other'))
              Padding(
                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                child: _buildTextField(
                  controller: _painAreaOtherController,
                  label: _getTranslation('other', currentLanguage),
                ),
              ),
            
            const SizedBox(height: 16),
            _buildRadioGroup(
              title: _getTranslation('symptom_start', currentLanguage),
              value: _symptomStart,
              options: {
                'today': _getTranslation('today', currentLanguage),
                'yesterday': _getTranslation('yesterday', currentLanguage),
                '2-3days': _getTranslation('2-3days', currentLanguage),
                '1week': _getTranslation('1week', currentLanguage),
                '1month+': _getTranslation('1month+', currentLanguage),
              },
              onChanged: (value) => setState(() => _symptomStart = value!),
            ),
            
            Text(_getTranslation('pain_level', currentLanguage), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _painLevel,
              min: 1,
              max: 10,
              divisions: 9,
              label: _painLevel.round().toString(),
              onChanged: (value) => setState(() => _painLevel = value),
            ),
            Text('${_painLevel.toInt()} / 10', textAlign: TextAlign.center),
            
            const SizedBox(height: 24),
            
            // 3. 상세 증상
            _buildSectionTitle(_getTranslation('symptoms', currentLanguage)),
            Text(_getTranslation('respiratory', currentLanguage), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildSymptomCheckbox('fever', _respiratorySymptoms),
            _buildSymptomCheckbox('chills', _respiratorySymptoms),
            _buildSymptomCheckbox('cough', _respiratorySymptoms),
            _buildSymptomCheckbox('runny_nose', _respiratorySymptoms),
            _buildSymptomCheckbox('phlegm', _respiratorySymptoms),
            _buildSymptomCheckbox('sore_throat', _respiratorySymptoms),
            
            const SizedBox(height: 16),
            Text(_getTranslation('digestive', currentLanguage), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildSymptomCheckbox('abdominal_pain', _digestiveSymptoms),
            _buildSymptomCheckbox('heartburn', _digestiveSymptoms),
            _buildSymptomCheckbox('nausea', _digestiveSymptoms),
            _buildSymptomCheckbox('diarrhea', _digestiveSymptoms),
            _buildSymptomCheckbox('constipation', _digestiveSymptoms),
            
            const SizedBox(height: 16),
            Text(_getTranslation('pain_other', currentLanguage), 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            _buildSymptomCheckbox('headache', _painSymptoms),
            _buildSymptomCheckbox('dizziness', _painSymptoms),
            _buildSymptomCheckbox('muscle_pain', _painSymptoms),
            _buildSymptomCheckbox('itching', _painSymptoms),
            _buildSymptomCheckbox('menstrual_pain', _painSymptoms),
            
            const SizedBox(height: 24),
            
            // 4. 과거력
            _buildSectionTitle(_getTranslation('medical_history', currentLanguage)),
            CheckboxListTile(
              title: Text(_getTranslation('taking_medicine', currentLanguage)),
              value: _takingMedicine,
              onChanged: (value) => setState(() => _takingMedicine = value!),
              contentPadding: EdgeInsets.zero,
            ),
            if (_takingMedicine)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
                child: _buildTextField(
                  controller: _medicineController,
                  label: _getTranslation('taking_medicine', currentLanguage),
                ),
              ),
            
            CheckboxListTile(
              title: Text(_getTranslation('has_allergy', currentLanguage)),
              value: _hasAllergy,
              onChanged: (value) => setState(() => _hasAllergy = value!),
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasAllergy)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
                child: _buildTextField(
                  controller: _allergyController,
                  label: _getTranslation('has_allergy', currentLanguage),
                ),
              ),
            
            if (_gender == 'female')
              _buildRadioGroup(
                title: _getTranslation('pregnant', currentLanguage),
                value: _pregnant == true ? 'yes' : (_pregnant == false ? 'no' : ''),
                options: {
                  'yes': _getTranslation('yes', currentLanguage),
                  'no': _getTranslation('no', currentLanguage),
                },
                onChanged: (value) => setState(() => _pregnant = value == 'yes'),
              ),
            
            const SizedBox(height: 24),
            
            // 5. 협조 요청
            _buildSectionTitle(_getTranslation('special_requests', currentLanguage)),
            _buildSpecialRequestCheckbox('speak_slowly'),
            _buildSpecialRequestCheckbox('explain_english'),
            _buildSpecialRequestCheckbox('use_translator'),
            _buildSpecialRequestCheckbox('write_instructions'),
            
            const SizedBox(height: 32),
            
            // PDF 생성 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generatePDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 28),
                label: Text(
                  _getTranslation('save_pdf', currentLanguage),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Text(
                _getTranslation('pdf_tip', currentLanguage),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF44336),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
                  return lang == 'ko' ? '$label을(를) 입력해주세요' : 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _birthDate = date;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: '${_getTranslation('birth_date', currentLanguage)} *',
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            _birthDate != null
                ? DateFormat('yyyy-MM-dd').format(_birthDate!)
                : '',
          ),
        ),
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

  Widget _buildPainAreaCheckbox(String area) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return CheckboxListTile(
      title: Text(_getTranslation(area, currentLanguage)),
      value: _painAreas.contains(area),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _painAreas.add(area);
          } else {
            _painAreas.remove(area);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSymptomCheckbox(String symptom, List<String> list) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return CheckboxListTile(
      title: Text(_getTranslation(symptom, currentLanguage)),
      value: list.contains(symptom),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            list.add(symptom);
          } else {
            list.remove(symptom);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSpecialRequestCheckbox(String request) {
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.currentLanguage;
    
    return CheckboxListTile(
      title: Text(_getTranslation(request, currentLanguage)),
      value: _specialRequests.contains(request),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _specialRequests.add(request);
          } else {
            _specialRequests.remove(request);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return '한국어';
    }
  }
}
