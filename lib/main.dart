import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('saved_posts');
  await Hive.openBox('user_data');
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => LanguageService()..loadLanguage()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'YONSEI BRIDGE',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0038A8),
                primary: const Color(0xFF0038A8),
                secondary: const Color(0xFF6B4EFF),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // 페이지 전환 시 흰색 깜빡임 방지 - 부드러운 Fade 전환
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            // ✅ 웹 전용 반응형 래퍼: 모바일 앱이 PC에서도 모바일 사이즈로 표시
            builder: (context, child) {
              if (!kIsWeb) return child!;
              return _WebMobileFrame(child: child!);
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // ✅ Bug 2 Fix: AuthService.checkLoginStatus()를 먼저 호출하여
    // _currentUserId / _currentUserName / _currentUserPermission 등
    // Provider 내부 상태를 SharedPreferences에서 완전히 복원한 뒤 라우팅한다.
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkLoginStatus();

    // 스플래시 최소 노출 시간 보장
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (authService.isLoggedIn) {
      // StorageService에도 userId 반영 (북마크 스코프 격리)
      Provider.of<StorageService>(context, listen: false)
          .setCurrentUser(authService.currentUserId);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0038A8),
              Color(0xFF6B4EFF),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/yonsei_bridge_logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 웹 전용 모바일 프레임 래퍼 ──────────────────────────────────────────────
/// 웹 브라우저에서 앱을 열었을 때 스마트폰처럼 중앙 정렬 + 최대 너비 500px로
/// 표시하여 모바일 UI가 PC 화면에서 늘어나 보이지 않도록 한다.
class _WebMobileFrame extends StatelessWidget {
  final Widget child;
  const _WebMobileFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 바깥 영역 어두운 배경
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRect(
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
