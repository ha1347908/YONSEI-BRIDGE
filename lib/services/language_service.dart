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
      },
    };
  }
}
