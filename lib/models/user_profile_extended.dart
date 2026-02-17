import 'package:cloud_firestore/cloud_firestore.dart';

/// Student type enumeration
enum StudentType {
  degree,        // 학위생
  exchange,      // 교환/방문/어학연수생
}

/// Housing type enumeration
enum HousingType {
  dormitory,     // 기숙사
  studio,        // 자취/원룸
  other,         // 기타
}

/// Korean proficiency level
enum KoreanLevel {
  noTopik,       // No TOPIK
  level12,       // Level 1-2
  level34,       // Level 3-4
  level56,       // Level 5-6
}

/// Extended user profile model with Living Setup data
class UserProfileExtended {
  final String userId;
  final String nickname;
  final String? profilePhotoUrl;
  
  // Student Information
  final StudentType studentType;
  final String department;  // 학과/소속
  
  // Living Setup Information
  final DateTime? entryDate;           // 한국 입국일
  final HousingType? housingType;      // 주거 형태
  final String? housingOther;          // 기타 주거 형태 (직접 입력)
  final KoreanLevel? koreanLevel;      // 한국어 숙련도
  final String? dietaryPreference;     // 식단 취향
  final List<String> interests;        // 관심사 (최소 3개)
  
  // Visa Information
  final String? visaType;              // 비자 타입
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileExtended({
    required this.userId,
    required this.nickname,
    this.profilePhotoUrl,
    required this.studentType,
    required this.department,
    this.entryDate,
    this.housingType,
    this.housingOther,
    this.koreanLevel,
    this.dietaryPreference,
    this.interests = const [],
    this.visaType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert StudentType to string
  static String studentTypeToString(StudentType type) {
    switch (type) {
      case StudentType.degree:
        return 'degree';
      case StudentType.exchange:
        return 'exchange';
    }
  }

  /// Convert string to StudentType
  static StudentType stringToStudentType(String type) {
    switch (type) {
      case 'degree':
        return StudentType.degree;
      case 'exchange':
        return StudentType.exchange;
      default:
        return StudentType.degree;
    }
  }

  /// Convert HousingType to string
  static String housingTypeToString(HousingType? type) {
    if (type == null) return '';
    switch (type) {
      case HousingType.dormitory:
        return 'dormitory';
      case HousingType.studio:
        return 'studio';
      case HousingType.other:
        return 'other';
    }
  }

  /// Convert string to HousingType
  static HousingType? stringToHousingType(String? type) {
    if (type == null || type.isEmpty) return null;
    switch (type) {
      case 'dormitory':
        return HousingType.dormitory;
      case 'studio':
        return HousingType.studio;
      case 'other':
        return HousingType.other;
      default:
        return null;
    }
  }

  /// Convert KoreanLevel to string
  static String koreanLevelToString(KoreanLevel? level) {
    if (level == null) return '';
    switch (level) {
      case KoreanLevel.noTopik:
        return 'no_topik';
      case KoreanLevel.level12:
        return 'level_1_2';
      case KoreanLevel.level34:
        return 'level_3_4';
      case KoreanLevel.level56:
        return 'level_5_6';
    }
  }

  /// Convert string to KoreanLevel
  static KoreanLevel? stringToKoreanLevel(String? level) {
    if (level == null || level.isEmpty) return null;
    switch (level) {
      case 'no_topik':
        return KoreanLevel.noTopik;
      case 'level_1_2':
        return KoreanLevel.level12;
      case 'level_3_4':
        return KoreanLevel.level34;
      case 'level_5_6':
        return KoreanLevel.level56;
      default:
        return null;
    }
  }

  /// Create from Firestore
  factory UserProfileExtended.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserProfileExtended(
      userId: data['user_id'] as String? ?? documentId,
      nickname: data['nickname'] as String? ?? '',
      profilePhotoUrl: data['profile_photo_url'] as String?,
      studentType: stringToStudentType(data['student_type'] as String? ?? 'degree'),
      department: data['department'] as String? ?? '',
      entryDate: (data['entry_date'] as Timestamp?)?.toDate(),
      housingType: stringToHousingType(data['housing_type'] as String?),
      housingOther: data['housing_other'] as String?,
      koreanLevel: stringToKoreanLevel(data['korean_level'] as String?),
      dietaryPreference: data['dietary_preference'] as String?,
      interests: (data['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      visaType: data['visa_type'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'nickname': nickname,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      'student_type': studentTypeToString(studentType),
      'department': department,
      if (entryDate != null) 'entry_date': Timestamp.fromDate(entryDate!),
      if (housingType != null) 'housing_type': housingTypeToString(housingType),
      if (housingOther != null) 'housing_other': housingOther,
      if (koreanLevel != null) 'korean_level': koreanLevelToString(koreanLevel),
      if (dietaryPreference != null) 'dietary_preference': dietaryPreference,
      'interests': interests,
      if (visaType != null) 'visa_type': visaType,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with method
  UserProfileExtended copyWith({
    String? userId,
    String? nickname,
    String? profilePhotoUrl,
    StudentType? studentType,
    String? department,
    DateTime? entryDate,
    HousingType? housingType,
    String? housingOther,
    KoreanLevel? koreanLevel,
    String? dietaryPreference,
    List<String>? interests,
    String? visaType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileExtended(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      studentType: studentType ?? this.studentType,
      department: department ?? this.department,
      entryDate: entryDate ?? this.entryDate,
      housingType: housingType ?? this.housingType,
      housingOther: housingOther ?? this.housingOther,
      koreanLevel: koreanLevel ?? this.koreanLevel,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      interests: interests ?? this.interests,
      visaType: visaType ?? this.visaType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Department/Major data for all languages
class DepartmentData {
  static const List<Map<String, String>> departments = [
    {
      'id': 'korean_lang_lit',
      'ko': '국어국문학',
      'en': 'Korean Language & Literature',
      'zh': '国语国文学',
      'ja': '国語国文学',
    },
    {
      'id': 'english_lang_lit',
      'ko': '영어영문학',
      'en': 'English Language & Literature',
      'zh': '英语英文学',
      'ja': '英語英文学',
    },
    {
      'id': 'history_culture',
      'ko': '역사문화학',
      'en': 'History & Culture',
      'zh': '历史文化学',
      'ja': '歴史文化学',
    },
    {
      'id': 'philosophy',
      'ko': '철학',
      'en': 'Philosophy',
      'zh': '哲学',
      'ja': '哲学',
    },
    {
      'id': 'business_admin',
      'ko': '경영학',
      'en': 'Business Administration',
      'zh': '工商管理学',
      'ja': '経営学',
    },
    {
      'id': 'economics',
      'ko': '경제학',
      'en': 'Economics',
      'zh': '经济学',
      'ja': '経済学',
    },
    {
      'id': 'global_public_admin',
      'ko': '글로벌행정학',
      'en': 'Global Public Administration',
      'zh': '全球行政学',
      'ja': 'グローバル行政学',
    },
    {
      'id': 'international_relations',
      'ko': '국제관계학',
      'en': 'International Relations',
      'zh': '国际关系学',
      'ja': '国際関係学',
    },
    {
      'id': 'eass',
      'ko': '동아시아국제학부',
      'en': 'East Asian International Studies (EASS)',
      'zh': '东亚国际学部',
      'ja': '東アジア国際学部',
    },
    {
      'id': 'industrial_design',
      'ko': '산업디자인학',
      'en': 'Industrial Design',
      'zh': '工业设计学',
      'ja': '産業デザイン学',
    },
    {
      'id': 'visual_design',
      'ko': '시각디자인학',
      'en': 'Visual Communication Design',
      'zh': '视觉传达设计学',
      'ja': '視覚デザイン学',
    },
    {
      'id': 'digital_arts',
      'ko': '디지털아트',
      'en': 'Digital Arts',
      'zh': '数字艺术',
      'ja': 'デジタルアート',
    },
    {
      'id': 'physics_engineering',
      'ko': '물리및공학물리학',
      'en': 'Physics & Engineering Physics',
      'zh': '物理与工程物理学',
      'ja': '物理および工学物理学',
    },
    {
      'id': 'chemistry_medical',
      'ko': '화학및의화학',
      'en': 'Chemistry & Medical Chemistry',
      'zh': '化学与医用化学',
      'ja': '化学および医化学',
    },
    {
      'id': 'bio_science_tech',
      'ko': '생명과학기술학',
      'en': 'Biological Science and Technology',
      'zh': '生命科学技术学',
      'ja': '生命科学技術学',
    },
    {
      'id': 'packaging_logistics',
      'ko': '패키징및물류학',
      'en': 'Packaging & Logistics',
      'zh': '包装与物流学',
      'ja': 'パッケージングおよび物流学',
    },
    {
      'id': 'env_energy_eng',
      'ko': '환경에너지공학부',
      'en': 'Environmental & Energy Engineering',
      'zh': '环境能源工程学部',
      'ja': '環境エネルギー工学部',
    },
    {
      'id': 'ai_semiconductor',
      'ko': 'AI반도체학부',
      'en': 'AI Semiconductor Engineering',
      'zh': 'AI半导体学部',
      'ja': 'AI半導体学部',
    },
    {
      'id': 'rc_convergence',
      'ko': 'RC융합대학',
      'en': 'RC Convergence College',
      'zh': 'RC融合大学',
      'ja': 'RC融合大学',
    },
    {
      'id': 'global_elite',
      'ko': '글로벌엘리트학부',
      'en': 'Global Elite Division',
      'zh': '全球精英学部',
      'ja': 'グローバルエリート学部',
    },
    {
      'id': 'medicine',
      'ko': '의과대학',
      'en': 'College of Medicine',
      'zh': '医学院',
      'ja': '医科大学',
    },
    {
      'id': 'nursing',
      'ko': '간호대학',
      'en': 'College of Nursing',
      'zh': '护理学院',
      'ja': '看護大学',
    },
    {
      'id': 'international_affairs',
      'ko': '국제교류원 소속',
      'en': 'Office of International Affairs',
      'zh': '国际交流院',
      'ja': '国際交流院',
    },
    {
      'id': 'other',
      'ko': '기타(직접 입력)',
      'en': 'Other(Direct Input)',
      'zh': '其他(直接输入)',
      'ja': 'その他(直接入力)',
    },
  ];

  static String getDepartmentName(String id, String languageCode) {
    final dept = departments.firstWhere(
      (d) => d['id'] == id,
      orElse: () => departments.last,
    );
    return dept[languageCode] ?? dept['en'] ?? id;
  }
}

/// Interest tags data
class InterestTags {
  static const List<Map<String, String>> interests = [
    {'id': 'christian', 'ko': '기독교 교제', 'en': 'Christian Fellowship', 'zh': '基督教团契', 'ja': 'キリスト教交わり'},
    {'id': 'catholic', 'ko': '천주교', 'en': 'Catholic', 'zh': '天主教', 'ja': 'カトリック'},
    {'id': 'islam', 'ko': '이슬람', 'en': 'Islam', 'zh': '伊斯兰教', 'ja': 'イスラム教'},
    {'id': 'buddhism', 'ko': '불교', 'en': 'Buddhism', 'zh': '佛教', 'ja': '仏教'},
    {'id': 'soccer', 'ko': '축구', 'en': 'Soccer', 'zh': '足球', 'ja': 'サッカー'},
    {'id': 'basketball', 'ko': '농구', 'en': 'Basketball', 'zh': '篮球', 'ja': 'バスケットボール'},
    {'id': 'gym', 'ko': '헬스/웨이트', 'en': 'Gym/Weightlifting', 'zh': '健身/举重', 'ja': 'ジム/ウエイトリフティング'},
    {'id': 'running', 'ko': '러닝/마라톤', 'en': 'Running', 'zh': '跑步/马拉松', 'ja': 'ランニング/マラソン'},
    {'id': 'kpop', 'ko': 'K-Pop', 'en': 'K-Pop', 'zh': 'K-Pop', 'ja': 'K-Pop'},
    {'id': 'kdrama', 'ko': 'K-Drama', 'en': 'K-Drama', 'zh': 'K-Drama', 'ja': 'K-Drama'},
    {'id': 'movies', 'ko': '영화/넷플릭스', 'en': 'Movies/Netflix', 'zh': '电影/Netflix', 'ja': '映画/Netflix'},
    {'id': 'cooking', 'ko': '요리/맛집', 'en': 'Cooking/Foodies', 'zh': '烹饪/美食', 'ja': '料理/グルメ'},
    {'id': 'cafe', 'ko': '카페/디저트', 'en': 'Cafes/Desserts', 'zh': '咖啡厅/甜点', 'ja': 'カフェ/デザート'},
    {'id': 'photography', 'ko': '사진/영상', 'en': 'Photography/Film', 'zh': '摄影/影像', 'ja': '写真/映像'},
    {'id': 'travel', 'ko': '여행', 'en': 'Traveling', 'zh': '旅行', 'ja': '旅行'},
    {'id': 'language_exchange', 'ko': '언어 교환', 'en': 'Language Exchange', 'zh': '语言交换', 'ja': '言語交換'},
    {'id': 'coding', 'ko': '코딩/IT', 'en': 'Coding/IT', 'zh': '编程/IT', 'ja': 'コーディング/IT'},
    {'id': 'startup', 'ko': '창업/비즈니스', 'en': 'Startup/Business', 'zh': '创业/商业', 'ja': '起業/ビジネス'},
    {'id': 'volunteer', 'ko': '봉사활동', 'en': 'Volunteer Work', 'zh': '志愿活动', 'ja': 'ボランティア活動'},
    {'id': 'hiking', 'ko': '등산', 'en': 'Hiking', 'zh': '登山', 'ja': '登山'},
    {'id': 'gaming', 'ko': '게임/E-스포츠', 'en': 'Gaming', 'zh': '游戏/电竞', 'ja': 'ゲーム/Eスポーツ'},
    {'id': 'art', 'ko': '미술/전시회', 'en': 'Art/Museums', 'zh': '美术/展览', 'ja': '美術/展覧会'},
    {'id': 'music', 'ko': '악기 연주', 'en': 'Music/Instrument', 'zh': '乐器演奏', 'ja': '楽器演奏'},
    {'id': 'fashion', 'ko': '패션/뷰티', 'en': 'Fashion/Beauty', 'zh': '时尚/美容', 'ja': 'ファッション/美容'},
  ];

  static String getInterestName(String id, String languageCode) {
    final interest = interests.firstWhere(
      (i) => i['id'] == id,
      orElse: () => {'id': id, 'ko': id, 'en': id, 'zh': id, 'ja': id},
    );
    return interest[languageCode] ?? interest['en'] ?? id;
  }
}

/// Visa type data
class VisaData {
  static const List<Map<String, String>> visaTypes = [
    {
      'id': 'd2_1_4',
      'ko': 'D-2-1~4: 학위 과정 (Degree Seeking)',
      'en': 'Degree Seeking (D-2-1~4)',
      'zh': '正规学位课程 (D-2-1~4)',
      'ja': '学位課程 (D-2-1~4)',
    },
    {
      'id': 'd2_6',
      'ko': 'D-2-6: 교환학생 (Exchange Student)',
      'en': 'Exchange Student (D-2-6)',
      'zh': '交换生 (D-2-6)',
      'ja': '交換留学生 (D-2-6)',
    },
    {
      'id': 'd2_8',
      'ko': 'D-2-8: 방문학생 (Visiting Student)',
      'en': 'Visiting Student (D-2-8)',
      'zh': '访问学生 (D-2-8)',
      'ja': '訪問学生 (D-2-8)',
    },
    {
      'id': 'd4_1',
      'ko': 'D-4-1: 어학연수생 (Language Trainee)',
      'en': 'Korean Language Trainee (D-4-1)',
      'zh': '语言研修生 (D-4-1)',
      'ja': '韓国語研修生 (D-4-1)',
    },
    {
      'id': 'd10',
      'ko': 'D-10: 구직 비자 (Job Seeker)',
      'en': 'Job Seeker (D-10-1, 2)',
      'zh': '求职签证 (D-10-1, 2)',
      'ja': '求職ビザ (D-10-1, 2)',
    },
    {
      'id': 'f4',
      'ko': 'F-4: 재외동포 (Overseas Korean)',
      'en': 'Overseas Korean (F-4)',
      'zh': '在外同胞 (F-4)',
      'ja': '在外同胞 (F-4)',
    },
    {
      'id': 'f2_f5',
      'ko': 'F-2 / F-5: 거주 및 영주 (Resident / Permanent)',
      'en': 'Resident / Permanent Resident (F-2, F-5)',
      'zh': '居住及永住 (F-2, F-5)',
      'ja': '居住および永住 (F-2, F-5)',
    },
    {
      'id': 'f6',
      'ko': 'F-6: 결혼이민 (Marriage Migrant)',
      'en': 'Marriage Migrant (F-6)',
      'zh': '结婚移民 (F-6)',
      'ja': '結婚移民 (F-6)',
    },
    {
      'id': 'other',
      'ko': '기타: (직접 입력)',
      'en': 'Other (Manual Input)',
      'zh': '其他 (手动输入)',
      'ja': 'その他 (直接入力)',
    },
  ];

  static String getVisaName(String id, String languageCode) {
    final visa = visaTypes.firstWhere(
      (v) => v['id'] == id,
      orElse: () => visaTypes.last,
    );
    return visa[languageCode] ?? visa['en'] ?? id;
  }
}
