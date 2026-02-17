import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'ko';
  
  String get currentLanguage => _currentLanguage;
  
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'ko';
    notifyListeners();
  }
  
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }
  
  String translate(String key) {
    final translations = _getTranslations();
    return translations[_currentLanguage]?[key] ?? translations['ko']?[key] ?? key;
  }
  
  Map<String, Map<String, String>> _getTranslations() {
    return {
      'ko': {
        // 앱 공통
        'app_name': 'YONSEI BRIDGE',
        'welcome': '환영합니다',
        'welcome_message': '안녕하세요',
        'greeting': '님!',
        'student': '학생',
        'we_connect_people': 'WE CONNECT PEOPLE',
        'login': '로그인',
        'signup': '회원가입',
        'logout': '로그아웃',
        'settings': '설정',
        'save': '저장',
        'cancel': '취소',
        'confirm': '확인',
        'delete': '삭제',
        'edit': '편집',
        'submit': '제출',
        'loading': '로딩 중...',
        
        // 게시판
        'free_board': '자유게시판',
        'free_board_desc': '누구나 자유롭게 글을 작성할 수 있습니다',
        'living_setup': '리빙셋업',
        'living_setup_desc': '입국부터 정착까지 단계별 가이드',
        'transportation': '원주시 교통정보',
        'transportation_desc': '버스, 택시, 교통편 정보',
        'useful_info': '유용한 정보글',
        'useful_info_desc': '생활 꿀팁과 유용한 정보',
        'campus_info': '미래캠퍼스 정보',
        'campus_info_desc': '캠퍼스 시설, 학사 일정 정보',
        'need_job': '니드잡',
        'need_job_desc': '유학생 특화 구인 정보',
        'hospital_info': '원주시 병원정보',
        'hospital_info_desc': '병원 정보 및 의료 지원',
        'restaurants': '원주시 맛집, 카페',
        'restaurants_desc': '맛집과 카페 추천',
        'clubs': '동아리 소개',
        'clubs_desc': '미래캠퍼스 동아리 정보',
        'korean_exchange': '한국 학생과의 교류',
        'korean_exchange_desc': '한국 학생들과 소통하기',
        'about': '연세브릿지에 대하여',
        'about_desc': '앱 소개 및 이용 안내',
        
        // 메뉴
        'saved_posts': '저장된 게시물',
        'chat': '채팅',
        'notifications': '알림',
        'notification_settings': '알림 설정',
        'push_notification_manage': '푸시 알림 관리',
        'profile': '프로필',
        'profile_edit': '프로필 편집',
        'language': '언어 설정',
        'language_select': '언어 선택',
        'delete_account': '회원 탈퇴',
        
        // 설정 섹션
        'app_settings': '앱 설정',
        'account': '계정',
        'info': '정보',
        'app_version': '앱 버전',
        'terms_of_service': '이용약관',
        'privacy_policy': '개인정보처리방침',
        
        // 다이얼로그 메시지
        'logout_confirm': '로그아웃 하시겠습니까?',
        'delete_account_confirm': '정말로 탈퇴하시겠습니까?\n\n모든 데이터가 삭제되며, 복구할 수 없습니다.',
        'delete_account_complete': '회원 탈퇴가 완료되었습니다',
        'language_changed': '언어가 변경되었습니다',
        'coming_soon': '준비 중',
        
        // 메시지
        'no_posts': '게시글이 없습니다',
        'no_saved_posts': '저장된 게시물이 없습니다',
        'post_saved': '게시글이 저장되었습니다',
        'post_unsaved': '저장이 취소되었습니다',
        
        // Living Setup
        'living_setup_title': '당신의 한국 생활, \'검색\'하지 말고 \'리빙셋업\' 하세요!',
        'living_setup_intro': '한국에 도착한 순간부터 개강까지, 무엇을 해야 할지 몰라 막막하신가요?\n연세브릿지 리빙셋업이 유학생의 시계에 딱 맞춘 \'생존 타임라인\'을 보내드립니다.',
        'living_setup_feature1_title': '📅 알아서 챙겨주는 일정',
        'living_setup_feature1_desc': '수강신청, ARC 신청, 건강검진 등 놓치면 안 될 학사 일정을 미리 알려드려요.',
        'living_setup_feature2_title': '🏠 바로 쓰는 생활 팁',
        'living_setup_feature2_desc': '기숙사 보일러 작동법부터 쓰레기 분리수거, 유심 개통까지 영상과 사진으로 쉽게 설명합니다.',
        'living_setup_feature3_title': '🚀 복잡한 인증 없이',
        'living_setup_feature3_desc': '한국 휴대폰 번호가 없어도 괜찮아요! 가입 즉시 필수 정보를 확인하세요.',
        'start_living_setup': '리빙셋업 시작하기',
        'close': '닫기',
        
        // Signup & Profile Setup
        'student_type': '학생 유형',
        'degree_student': '학위생',
        'exchange_student': '교환/방문/어학연수생',
        'department': '소속학과',
        'select_department': '학과를 선택하세요',
        'entry_date': '한국 입국일',
        'select_entry_date': '입국일을 선택하세요',
        'housing_type': '주거 형태',
        'dormitory': '기숙사',
        'studio': '자취/원룸',
        'housing_other': '기타',
        'korean_proficiency': '한국어 숙련도',
        'no_topik': 'No TOPIK (I need help with everything in English/my language)',
        'level_1_2': 'Level 1~2 (I can order food but need help at the bank/hospital)',
        'level_3_4': 'Level 3~4 (I can handle daily life but academic tasks are hard)',
        'level_5_6': 'Level 5~6 (I\'m comfortable with almost everything in Korean)',
        'dietary_preference': '식단 취향',
        'dietary_hint': '예: 할랄, 비건, 채식 등',
        'interests': '관심사',
        'select_interests': '최소 3개 이상 선택하세요',
        'visa_type': '비자 유형',
        'select_visa': '비자를 선택하세요',
        'profile_photo': '프로필 사진',
        'profile_photo_later': '프로필 사진은 가입 이후 설정 가능합니다',
        'complete_profile': '프로필 완성하기',
        'skip': '건너뛰기',
        
        // Notification Permission
        'notification_permission_title': '당신에게 꼭 필요한 정보를 놓치지 마세요! 🔔',
        'notification_permission_desc': '알림을 켜두시면 유학생 여러분의 정착을 돕는 \'리빙셋업\'의 핵심 정보를 실시간으로 보내드립니다.',
        'notification_feature1': '📅 개인별 타임라인: 비자 연장, 수강 신청 등 중요한 일정을 미리 챙겨드려요.',
        'notification_feature2': '🏠 생활 밀착 가이드: 오늘 쓰레기 배출 요일, 기숙사 공지 등을 바로 확인하세요.',
        'notification_feature3': '⚠️ 안심 알림: 긴급 상황 발생 시 대처법과 가까운 안심 병원 정보를 알려드려요.',
        'turn_on_notifications': '알림 설정하기',
        
        // Account Recovery
        'account_recovery': '계정 복구',
        'account_recovery_guide': '계정 복구 안내',
        'account_recovery_title': '계정을 복구하시겠습니까?',
        'account_recovery_desc': '계정 복구 절차는 다음과 같습니다:',
        'recovery_step1': '1. 관리자에게 연락하기',
        'recovery_step1_desc': '연세브릿지 관리자에게 이메일(admin@yonseibridge.com)로 연락주세요.',
        'recovery_step2': '2. 본인 인증',
        'recovery_step2_desc': '학생증 또는 재학증명서를 제출하여 본인임을 증명해주세요.',
        'recovery_step3': '3. 계정 복구 처리',
        'recovery_step3_desc': '관리자가 확인 후 24시간 내에 계정을 복구해드립니다.',
        'contact_admin': '관리자에게 연락',
        
        // D-4-1 Visa Warning
        'd4_1_job_warning': '아르바이트는 입국 후 6개월이 지나야 가능합니다',
      },
      'en': {
        // App common
        'app_name': 'YONSEI BRIDGE',
        'welcome': 'Welcome',
        'welcome_message': 'Hello',
        'greeting': '!',
        'student': 'Student',
        'we_connect_people': 'WE CONNECT PEOPLE',
        'login': 'Login',
        'signup': 'Sign Up',
        'logout': 'Logout',
        'settings': 'Settings',
        'save': 'Save',
        'cancel': 'Cancel',
        'confirm': 'Confirm',
        'delete': 'Delete',
        'edit': 'Edit',
        'submit': 'Submit',
        'loading': 'Loading...',
        
        // Boards
        'free_board': 'Free Board',
        'free_board_desc': 'Anyone can freely post',
        'living_setup': 'Living Setup',
        'living_setup_desc': 'Step-by-step guide from arrival to settlement',
        'transportation': 'Transportation Info',
        'transportation_desc': 'Bus, taxi, and transportation information',
        'useful_info': 'Useful Information',
        'useful_info_desc': 'Life tips and useful information',
        'campus_info': 'Campus Information',
        'campus_info_desc': 'Campus facilities and academic schedule',
        'need_job': 'Job Board',
        'need_job_desc': 'Job information for international students',
        'hospital_info': 'Hospital Information',
        'hospital_info_desc': 'Hospital information and medical support',
        'restaurants': 'Restaurants & Cafes',
        'restaurants_desc': 'Restaurant and cafe recommendations',
        'clubs': 'Club Introduction',
        'clubs_desc': 'Mirae Campus club information',
        'korean_exchange': 'Korean Exchange',
        'korean_exchange_desc': 'Connect with Korean students',
        'about': 'About Yonsei Bridge',
        'about_desc': 'App introduction and usage guide',
        
        // Menu
        'saved_posts': 'Saved Posts',
        'chat': 'Chat',
        'notifications': 'Notifications',
        'notification_settings': 'Notification Settings',
        'push_notification_manage': 'Manage push notifications',
        'profile': 'Profile',
        'profile_edit': 'Edit Profile',
        'language': 'Language',
        'language_select': 'Select Language',
        'delete_account': 'Delete Account',
        
        // Settings sections
        'app_settings': 'App Settings',
        'account': 'Account',
        'info': 'Information',
        'app_version': 'App Version',
        'terms_of_service': 'Terms of Service',
        'privacy_policy': 'Privacy Policy',
        
        // Dialog messages
        'logout_confirm': 'Are you sure you want to logout?',
        'delete_account_confirm': 'Are you sure you want to delete your account?\n\nAll data will be deleted and cannot be recovered.',
        'delete_account_complete': 'Account deletion completed',
        'language_changed': 'Language changed',
        'coming_soon': 'Coming Soon',
        
        // Messages
        'no_posts': 'No posts available',
        'no_saved_posts': 'No saved posts',
        'post_saved': 'Post saved',
        'post_unsaved': 'Post removed from saved',
        
        // Living Setup
        'living_setup_title': 'Don\'t Waste Time Searching—Let \'Living Setup\' Handle Your Life in Korea!',
        'living_setup_intro': 'Are you feeling overwhelmed and unsure of what to do from the moment you land in Korea until classes start? Yonsei-Bridge\'s Living Setup provides a "Survival Timeline" perfectly synced with your schedule.',
        'living_setup_feature1_title': '📅 Automated Scheduling',
        'living_setup_feature1_desc': 'We\'ll notify you of essential academic dates, such as course registration, ARC (Alien Registration Card) applications, and health checkups.',
        'living_setup_feature2_title': '🏠 Practical Life Tips',
        'living_setup_feature2_desc': 'From operating your dormitory boiler to waste disposal and SIM card activation, we explain everything clearly with photos and videos.',
        'living_setup_feature3_title': '🚀 No Complex Authentication',
        'living_setup_feature3_desc': 'It\'s okay if you don\'t have a Korean phone number yet! Access essential information immediately upon signing up.',
        'start_living_setup': 'Start Living Setup',
        'close': 'Close',
        
        // Signup & Profile Setup
        'student_type': 'Student Type',
        'degree_student': 'Degree-Seeking Student',
        'exchange_student': 'Exchange/Visiting/Language Student',
        'department': 'Department/Major',
        'select_department': 'Select your department',
        'entry_date': 'Arrival Date in Korea',
        'select_entry_date': 'Select your arrival date',
        'housing_type': 'Housing',
        'dormitory': 'University Dormitory',
        'studio': 'Studio (One-room)',
        'housing_other': 'Other',
        'korean_proficiency': 'Korean Proficiency',
        'no_topik': 'No TOPIK (I need help with everything in English/my language)',
        'level_1_2': 'Level 1~2 (I can order food but need help at the bank/hospital)',
        'level_3_4': 'Level 3~4 (I can handle daily life but academic tasks are hard)',
        'level_5_6': 'Level 5~6 (I\'m comfortable with almost everything in Korean)',
        'dietary_preference': 'Dietary Preference',
        'dietary_hint': 'e.g., Halal, Vegan, Vegetarian, etc.',
        'interests': 'Interests',
        'select_interests': 'Select at least 3 interests',
        'visa_type': 'Visa Type',
        'select_visa': 'Select your visa type',
        'profile_photo': 'Profile Photo',
        'profile_photo_later': 'Profile photo can be set after registration',
        'complete_profile': 'Complete Profile',
        'skip': 'Skip',
        
        // Notification Permission
        'notification_permission_title': 'Don\'t miss out on your Survival Guide! 🔔',
        'notification_permission_desc': 'Turn on notifications to receive personalized \'Living Setup\' updates just for you.',
        'notification_feature1': '📅 Personalized Timeline: Get reminders for ARC applications and course registration.',
        'notification_feature2': '🏠 Instant Life Tips: From trash disposal days to dormitory notices.',
        'notification_feature3': '⚠️ Health & Safety: Emergency alerts and nearby hospital info.',
        'turn_on_notifications': 'Turn on Notifications',
        
        // Account Recovery
        'account_recovery': 'Account Recovery',
        'account_recovery_guide': 'Account Recovery Guide',
        'account_recovery_title': 'Would you like to recover your account?',
        'account_recovery_desc': 'Account recovery procedure:',
        'recovery_step1': '1. Contact Administrator',
        'recovery_step1_desc': 'Please email the Yonsei Bridge administrator at admin@yonseibridge.com.',
        'recovery_step2': '2. Identity Verification',
        'recovery_step2_desc': 'Submit your student ID or enrollment certificate to verify your identity.',
        'recovery_step3': '3. Account Recovery Process',
        'recovery_step3_desc': 'After verification, your account will be recovered within 24 hours.',
        'contact_admin': 'Contact Administrator',
        
        // D-4-1 Visa Warning
        'd4_1_job_warning': 'Part-time work is only allowed 6 months after arrival',
      },
      'zh': {
        // 应用通用
        'app_name': 'YONSEI BRIDGE',
        'welcome': '欢迎',
        'welcome_message': '您好',
        'greeting': '!',
        'student': '学生',
        'we_connect_people': 'WE CONNECT PEOPLE',
        'login': '登录',
        'signup': '注册',
        'logout': '退出',
        'settings': '设置',
        'save': '保存',
        'cancel': '取消',
        'confirm': '确认',
        'delete': '删除',
        'edit': '编辑',
        'submit': '提交',
        'loading': '加载中...',
        
        // 版块
        'free_board': '自由版块',
        'free_board_desc': '任何人都可以自由发帖',
        'living_setup': '生活指南',
        'living_setup_desc': '从入境到定居的分步指南',
        'transportation': '交通信息',
        'transportation_desc': '公交、出租车和交通信息',
        'useful_info': '实用信息',
        'useful_info_desc': '生活小贴士和实用信息',
        'campus_info': '校园信息',
        'campus_info_desc': '校园设施和学术日程',
        'need_job': '求职招聘',
        'need_job_desc': '留学生专属招聘信息',
        'hospital_info': '医院信息',
        'hospital_info_desc': '医院信息和医疗支持',
        'restaurants': '餐厅咖啡馆',
        'restaurants_desc': '餐厅和咖啡馆推荐',
        'clubs': '社团介绍',
        'clubs_desc': '未来校区社团信息',
        'korean_exchange': '韩国学生交流',
        'korean_exchange_desc': '与韩国学生交流',
        'about': '关于延世桥梁',
        'about_desc': '应用介绍和使用指南',
        
        // 菜单
        'saved_posts': '已保存帖子',
        'chat': '聊天',
        'notifications': '通知',
        'notification_settings': '通知设置',
        'push_notification_manage': '管理推送通知',
        'profile': '个人资料',
        'profile_edit': '编辑个人资料',
        'language': '语言',
        'language_select': '选择语言',
        'delete_account': '删除账户',
        
        // 设置部分
        'app_settings': '应用设置',
        'account': '账户',
        'info': '信息',
        'app_version': '应用版本',
        'terms_of_service': '服务条款',
        'privacy_policy': '隐私政策',
        
        // 对话框消息
        'logout_confirm': '确定要退出吗?',
        'delete_account_confirm': '确定要删除账户吗?\n\n所有数据将被删除且无法恢复。',
        'delete_account_complete': '账户删除完成',
        'language_changed': '语言已更改',
        'coming_soon': '即将推出',
        
        // 消息
        'no_posts': '暂无帖子',
        'no_saved_posts': '暂无保存的帖子',
        'post_saved': '帖子已保存',
        'post_unsaved': '已取消保存',
        
        // Living Setup
        'living_setup_title': '告别繁琐搜索，让\'Living Setup\'开启你的韩国生活！',
        'living_setup_intro': '从抵达韩国那一刻起直至开学，你是否正因为不知所措而感到茫然？延世桥（Yonsei-Bridge）的 Living Setup 为留学生量身定制了完美的"生存时间轴"。',
        'living_setup_feature1_title': '📅 自动提醒重要日程',
        'living_setup_feature1_desc': '选课、ARC（外国人登录证）申请、健康检查等绝不能错过的学期安排，我们都会提前通知你。',
        'living_setup_feature2_title': '🏠 实用的生活指南',
        'living_setup_feature2_desc': '从宿舍地暖的使用方法到垃圾分类、SIM卡开通，我们将通过视频和照片为你详细解答。',
        'living_setup_feature3_title': '🚀 无需复杂认证',
        'living_setup_feature3_desc': '还没有韩国手机号？没关系！注册后即可立即查看所有核心生活资讯。',
        'start_living_setup': '开始生活指南',
        'close': '关闭',
        
        // Signup & Profile Setup
        'student_type': '学生类型',
        'degree_student': '学位生',
        'exchange_student': '交换/访问/语言研修生',
        'department': '所属专业',
        'select_department': '选择您的专业',
        'entry_date': '入境韩国日期',
        'select_entry_date': '选择入境日期',
        'housing_type': '居住形式',
        'dormitory': '学校宿舍',
        'studio': '自炊房/一居室',
        'housing_other': '其他',
        'korean_proficiency': '韩语熟练度',
        'no_topik': 'No TOPIK (I need help with everything in English/my language)',
        'level_1_2': 'Level 1~2 (I can order food but need help at the bank/hospital)',
        'level_3_4': 'Level 3~4 (I can handle daily life but academic tasks are hard)',
        'level_5_6': 'Level 5~6 (I\'m comfortable with almost everything in Korean)',
        'dietary_preference': '饮食偏好',
        'dietary_hint': '如：清真、纯素、素食等',
        'interests': '兴趣爱好',
        'select_interests': '至少选择3项',
        'visa_type': '签证类型',
        'select_visa': '选择您的签证类型',
        'profile_photo': '个人照片',
        'profile_photo_later': '个人照片可在注册后设置',
        'complete_profile': '完成个人资料',
        'skip': '跳过',
        
        // Notification Permission
        'notification_permission_title': '不要错过为您量身定制的生存指南！ 🔔',
        'notification_permission_desc': '开启通知，即可实时获取帮助您快速适应韩国生活的\'Living Setup\'核心信息。',
        'notification_feature1': '📅 个人定制时间轴: 提前提醒您外国人登录证(ARC)申请和选课等重要日程。',
        'notification_feature2': '🏠 贴心生活指南: 实时掌握垃圾分类日期、宿舍通知等实用信息。',
        'notification_feature3': '⚠️ 安全守护: 紧急情况应对方法及周边安心医院信息。',
        'turn_on_notifications': '开启通知',
        
        // Account Recovery
        'account_recovery': '账户恢复',
        'account_recovery_guide': '账户恢复指南',
        'account_recovery_title': '您想恢复账户吗？',
        'account_recovery_desc': '账户恢复流程如下：',
        'recovery_step1': '1. 联系管理员',
        'recovery_step1_desc': '请发送邮件至延世桥管理员邮箱：admin@yonseibridge.com',
        'recovery_step2': '2. 身份验证',
        'recovery_step2_desc': '提交学生证或在读证明以验证您的身份。',
        'recovery_step3': '3. 账户恢复处理',
        'recovery_step3_desc': '验证后，您的账户将在24小时内恢复。',
        'contact_admin': '联系管理员',
        
        // D-4-1 Visa Warning
        'd4_1_job_warning': '入境6个月后才可以打工',
      },
      'ja': {
        // アプリ共通
        'app_name': 'YONSEI BRIDGE',
        'welcome': 'ようこそ',
        'welcome_message': 'こんにちは',
        'greeting': 'さん!',
        'student': '学生',
        'we_connect_people': 'WE CONNECT PEOPLE',
        'login': 'ログイン',
        'signup': '新規登録',
        'logout': 'ログアウト',
        'settings': '設定',
        'save': '保存',
        'cancel': 'キャンセル',
        'confirm': '確認',
        'delete': '削除',
        'edit': '編集',
        'submit': '提出',
        'loading': '読み込み中...',
        
        // 掲示板
        'free_board': '自由掲示板',
        'free_board_desc': '誰でも自由に投稿できます',
        'living_setup': '生活セットアップ',
        'living_setup_desc': '入国から定住までのステップバイステップガイド',
        'transportation': '交通情報',
        'transportation_desc': 'バス、タクシー、交通情報',
        'useful_info': '役立つ情報',
        'useful_info_desc': '生活のヒントと役立つ情報',
        'campus_info': 'キャンパス情報',
        'campus_info_desc': 'キャンパス施設と学事日程',
        'need_job': '求人情報',
        'need_job_desc': '留学生向け求人情報',
        'hospital_info': '病院情報',
        'hospital_info_desc': '病院情報と医療サポート',
        'restaurants': 'レストラン・カフェ',
        'restaurants_desc': 'レストランとカフェのおすすめ',
        'clubs': 'サークル紹介',
        'clubs_desc': 'ミレキャンパスのサークル情報',
        'korean_exchange': '韓国人学生との交流',
        'korean_exchange_desc': '韓国人学生と交流する',
        'about': '延世ブリッジについて',
        'about_desc': 'アプリ紹介と使用ガイド',
        
        // メニュー
        'saved_posts': '保存した投稿',
        'chat': 'チャット',
        'notifications': '通知',
        'notification_settings': '通知設定',
        'push_notification_manage': 'プッシュ通知の管理',
        'profile': 'プロフィール',
        'profile_edit': 'プロフィール編集',
        'language': '言語',
        'language_select': '言語を選択',
        'delete_account': 'アカウント削除',
        
        // 設定セクション
        'app_settings': 'アプリ設定',
        'account': 'アカウント',
        'info': '情報',
        'app_version': 'アプリバージョン',
        'terms_of_service': '利用規約',
        'privacy_policy': 'プライバシーポリシー',
        
        // ダイアログメッセージ
        'logout_confirm': 'ログアウトしますか?',
        'delete_account_confirm': '本当にアカウントを削除しますか?\n\nすべてのデータが削除され、復元できません。',
        'delete_account_complete': 'アカウント削除が完了しました',
        'language_changed': '言語が変更されました',
        'coming_soon': '準備中',
        
        // メッセージ
        'no_posts': '投稿がありません',
        'no_saved_posts': '保存した投稿がありません',
        'post_saved': '投稿を保存しました',
        'post_unsaved': '保存を解除しました',
        
        // Living Setup
        'living_setup_title': '韓国生活、検索はもう卒業！『リビングセットアップ』にお任せください！',
        'living_setup_intro': '韓国に到着した瞬間から開講まで、何をすべきか分からず不安ではありませんか？延世ブリッジ（Yonsei-Bridge）のリビングセットアップが、留学生のスケジュールにぴったり合わせた「生存タイムライン」をお届けします。',
        'living_setup_feature1_title': '📅 お任せスケジュール管理',
        'living_setup_feature1_desc': '履修登録、外国人登録（ARC）の申請、健康診断など、見逃せない学事日程を事前にお知らせします。',
        'living_setup_feature2_title': '🏠 すぐに役立つ生活の知恵',
        'living_setup_feature2_desc': '寄宿舎のボイラーの使い方からゴミの分別、USIMカードの開通まで、動画や写真で分かりやすく説明します。',
        'living_setup_feature3_title': '🚀 複雑な認証は不要',
        'living_setup_feature3_desc': '韓国の電話番号がなくても大丈夫！加入後すぐに、必要な情報を確認できます。',
        'start_living_setup': 'リビングセットアップを開始',
        'close': '閉じる',
        
        // Signup & Profile Setup
        'student_type': '学生タイプ',
        'degree_student': '学位課程学生',
        'exchange_student': '交換/訪問/語学研修生',
        'department': '所属学科',
        'select_department': '学科を選択してください',
        'entry_date': '韓国入国日',
        'select_entry_date': '入国日を選択してください',
        'housing_type': '居住形態',
        'dormitory': '学校寄宿舎',
        'studio': 'ワンルーム/自炊',
        'housing_other': 'その他',
        'korean_proficiency': '韓国語熟練度',
        'no_topik': 'No TOPIK (I need help with everything in English/my language)',
        'level_1_2': 'Level 1~2 (I can order food but need help at the bank/hospital)',
        'level_3_4': 'Level 3~4 (I can handle daily life but academic tasks are hard)',
        'level_5_6': 'Level 5~6 (I\'m comfortable with almost everything in Korean)',
        'dietary_preference': '食事の好み',
        'dietary_hint': '例: ハラール、ビーガン、菜食など',
        'interests': '興味・関心',
        'select_interests': '最低3つ選択してください',
        'visa_type': 'ビザタイプ',
        'select_visa': 'ビザタイプを選択してください',
        'profile_photo': 'プロフィール写真',
        'profile_photo_later': 'プロフィール写真は登録後に設定できます',
        'complete_profile': 'プロフィール完成',
        'skip': 'スキップ',
        
        // Notification Permission
        'notification_permission_title': '必要な情報を見逃さないでください！ 🔔',
        'notification_permission_desc': '通知を有効にすると、留学生の皆様の定住を支援する「リビングセットアップ」の重要情報をリアルタイムで受け取れます。',
        'notification_feature1': '📅 個別タイムライン: ビザ延長、履修登録など重要なスケジュールを事前にお知らせします。',
        'notification_feature2': '🏠 生活密着ガイド: ゴミ出し日、寄宿舎のお知らせなどをすぐに確認できます。',
        'notification_feature3': '⚠️ 安心アラート: 緊急時の対処法と近くの安心病院情報をお知らせします。',
        'turn_on_notifications': '通知設定',
        
        // Account Recovery
        'account_recovery': 'アカウント回復',
        'account_recovery_guide': 'アカウント回復ガイド',
        'account_recovery_title': 'アカウントを回復しますか？',
        'account_recovery_desc': 'アカウント回復手順：',
        'recovery_step1': '1. 管理者に連絡',
        'recovery_step1_desc': '延世ブリッジ管理者(admin@yonseibridge.com)にメールでご連絡ください。',
        'recovery_step2': '2. 本人確認',
        'recovery_step2_desc': '学生証または在学証明書を提出して本人確認を行ってください。',
        'recovery_step3': '3. アカウント回復処理',
        'recovery_step3_desc': '確認後、24時間以内にアカウントを回復いたします。',
        'contact_admin': '管理者に連絡',
        
        // D-4-1 Visa Warning
        'd4_1_job_warning': 'アルバイトは入国6ヶ月後から可能です',
      },
    };
  }
}
