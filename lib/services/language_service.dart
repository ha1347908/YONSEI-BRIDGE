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
        'living_setup': '리빙셋업',
        'transportation': '원주시 교통정보',
        'useful_info': '유용한 정보글',
        'campus_info': '미래캠퍼스 정보',
        'need_job': '니드잡',
        'hospital_info': '원주시 병원정보',
        'restaurants': '원주시 맛집, 카페',
        'clubs': '동아리 소개',
        'korean_exchange': '한국 학생과의 교류',
        'about': '연세브릿지에 대하여',
        
        // 메뉴
        'saved_posts': '저장된 게시물',
        'notifications': '알림',
        'profile': '프로필',
        'language': '언어 설정',
        'delete_account': '회원 탈퇴',
        
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
        'living_setup': 'Living Setup',
        'transportation': 'Transportation Info',
        'useful_info': 'Useful Information',
        'campus_info': 'Campus Information',
        'need_job': 'Job Board',
        'hospital_info': 'Hospital Information',
        'restaurants': 'Restaurants & Cafes',
        'clubs': 'Club Introduction',
        'korean_exchange': 'Korean Exchange',
        'about': 'About Yonsei Bridge',
        
        // Menu
        'saved_posts': 'Saved Posts',
        'notifications': 'Notifications',
        'profile': 'Profile',
        'language': 'Language',
        'delete_account': 'Delete Account',
        
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
        'living_setup': '生活指南',
        'transportation': '交通信息',
        'useful_info': '实用信息',
        'campus_info': '校园信息',
        'need_job': '求职招聘',
        'hospital_info': '医院信息',
        'restaurants': '餐厅咖啡馆',
        'clubs': '社团介绍',
        'korean_exchange': '韩国学生交流',
        'about': '关于延世桥梁',
        
        // 菜单
        'saved_posts': '已保存帖子',
        'notifications': '通知',
        'profile': '个人资料',
        'language': '语言',
        'delete_account': '删除账户',
        
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
        'living_setup': '生活セットアップ',
        'transportation': '交通情報',
        'useful_info': '役立つ情報',
        'campus_info': 'キャンパス情報',
        'need_job': '求人情報',
        'hospital_info': '病院情報',
        'restaurants': 'レストラン・カフェ',
        'clubs': 'サークル紹介',
        'korean_exchange': '韓国人学生との交流',
        'about': '延世ブリッジについて',
        
        // メニュー
        'saved_posts': '保存した投稿',
        'notifications': '通知',
        'profile': 'プロフィール',
        'language': '言語',
        'delete_account': 'アカウント削除',
        
        // メッセージ
        'no_posts': '投稿がありません',
        'no_saved_posts': '保存した投稿がありません',
        'post_saved': '投稿を保存しました',
        'post_unsaved': '保存を解除しました',
      },
    };
  }
}
