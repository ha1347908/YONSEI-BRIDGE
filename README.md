# YONSEI BRIDGE (연세브릿지)

연세대학교 미래캠퍼스 국제학생을 위한 종합 지원 앱

<img src="assets/images/yonsei_bridge_logo.png" width="200" alt="YONSEI BRIDGE Logo">

## 📱 앱 소개

YONSEI BRIDGE는 연세대학교 미래캠퍼스의 국제학생들이 한국 생활에 빠르게 적응하고, 학교 생활을 원활하게 할 수 있도록 돕는 종합 지원 플랫폼입니다.

### ✨ 주요 기능

#### 🔐 회원가입 및 로그인
- 연세대학교 학생증 인증 시스템
- 로그인 정보 저장 기능
- 관리자 승인 프로세스

#### 📋 11개 게시판 시스템
1. **자유게시판** - 모든 사용자가 자유롭게 글을 작성할 수 있는 공간
2. **리빙셋업** - 생활 준비 정보 및 가이드
3. **원주시 교통정보** - 버스, 택시 등 교통 정보
4. **유용한 정보글** - 학교 생활에 도움이 되는 정보
5. **미래캠퍼스 정보** - 캠퍼스 시설 및 학사 정보
6. **니드잡** - 학생 맞춤 아르바이트 정보 및 이력서 작성
7. **원주시 병원정보** - 병원 정보 및 증상카드 작성
8. **원주시 맛집·카페 추천** - 음식점 및 카페 추천
9. **연세대학교 미래캠퍼스 동아리 소개** - 동아리 활동 정보
10. **한국 학생과의 교류** - 문화 교류 및 언어 교환
11. **연세브릿지에 대하여** - 앱 소개 및 공지사항

#### 💼 니드잡 이력서 작성
- 국제학생 맞춤 이력서 양식
- 개인정보, 비자/법적 상태, 언어 능력, 근무 선호도 등
- 관리자에게 직접 제출

#### 🏥 안심진료 증상카드
- 병원 방문 시 사용할 수 있는 증상카드 작성
- 다국어 지원 (한국어/영어/중국어/일본어)
- PDF 생성 및 저장 기능
- 한글 폰트 적용으로 의사에게 정확한 정보 전달

#### 🌍 다국어 지원
- 한국어 (Korean)
- 영어 (English)
- 중국어 간체 (简体中文)
- 일본어 (日本語)

#### 💾 게시물 저장 기능
- 관심 있는 게시물을 앱 내에 저장
- 오프라인에서도 저장된 게시물 확인 가능

## 🛠️ 기술 스택

### Flutter & Dart
- **Flutter**: 3.35.4
- **Dart**: 3.9.2

### 주요 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 상태 관리
  provider: 6.1.5+1
  
  # 로컬 저장소
  hive: 2.2.3
  hive_flutter: 1.1.0
  shared_preferences: 2.5.3
  
  # 이미지 처리
  image_picker: 1.1.2
  cached_network_image: 3.4.1
  
  # PDF 생성
  pdf: 3.11.3
  printing: 5.14.0
  
  # 기타
  intl: 0.19.0
  permission_handler: 11.3.1
  path_provider: 2.1.5
```

## 📦 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── models/                      # 데이터 모델
│   │   ├── board_category.dart
│   │   └── post.dart
│   ├── screens/                     # 화면
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── home_screen.dart
│   │   ├── board_screen.dart
│   │   ├── post_detail_screen.dart
│   │   ├── create_post_screen.dart
│   │   ├── resume_form_screen.dart
│   │   ├── symptom_card_screen.dart
│   │   ├── saved_posts_screen.dart
│   │   └── settings_screen.dart
│   └── services/                    # 서비스
│       ├── auth_service.dart
│       ├── language_service.dart
│       └── storage_service.dart
├── assets/
│   ├── images/                      # 이미지 파일
│   │   ├── yonsei_bridge_logo.png
│   │   ├── campus_background.jpg
│   │   └── slogan.png
│   └── icon/                        # 앱 아이콘
│       └── app_icon.png
├── fonts/
│   └── NotoSansKR-Regular.ttf      # 한글 폰트
├── android/                         # Android 설정
└── web/                            # Web 설정
```

## 🚀 시작하기

### 사전 요구사항
- Flutter 3.35.4 이상
- Dart 3.9.2 이상
- Android Studio / Xcode (선택사항)

### 설치 및 실행

1. **저장소 클론**
```bash
git clone https://github.com/ha1347908/YONSEI-BRIDGE.git
cd YONSEI-BRIDGE
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **앱 실행**

**웹으로 실행**:
```bash
flutter run -d chrome
```

**릴리즈 빌드 (웹)**:
```bash
flutter build web --release
cd build/web
python3 -m http.server 5060
```

**Android APK 빌드**:
```bash
flutter build apk --release
```

## 📱 스크린샷

(스크린샷 추가 예정)

## 🎯 향후 개발 계획

### 우선순위 높음
- [ ] Firebase 백엔드 연동
  - Firebase Authentication (이메일/비밀번호 인증)
  - Cloud Firestore (실시간 데이터베이스)
  - Firebase Storage (이미지 업로드)
  
- [ ] 관리자/매니저 권한 시스템
  - 역할 기반 접근 제어 (RBAC)
  - 관리자 대시보드
  - 게시물 승인/거부 시스템

- [ ] 사용자 메신저
  - 1:1 채팅 기능
  - 실시간 메시지 알림
  - 채팅 기록 저장

### 우선순위 중간
- [ ] 푸시 알림 (Firebase Cloud Messaging)
- [ ] 리빙셋업 타임라인 (도착일 기반 자동 알림)
- [ ] 오프라인 모드 강화

### 최적화
- [ ] 성능 개선
- [ ] UI/UX 개선
- [ ] 접근성 향상

## 👥 기여자

- **개발**: AI Assistant & User
- **디자인**: User
- **기획**: User

## 📄 라이선스

이 프로젝트는 교육 목적으로 개발되었습니다.

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 Issue를 통해 연락 주세요.

---

**YONSEI BRIDGE** - Connecting International Students at Yonsei University
