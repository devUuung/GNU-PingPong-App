// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnu_pingpong_app/screens/login.dart';
import 'package:gnu_pingpong_app/screens/home.dart';
import 'package:gnu_pingpong_app/screens/profile.dart';
import 'package:gnu_pingpong_app/screens/profile_edit.dart';
import 'package:gnu_pingpong_app/screens/change_password.dart';
import 'package:gnu_pingpong_app/screens/signup.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Supabase 클라이언트 인스턴스
final supabase = Supabase.instance.client;

Future<void> saveFcmTokenToSupabase() async {
  if (Firebase.apps.isEmpty) {
    debugPrint('Firebase 앱이 아직 초기화되지 않았습니다.');
    return;
  }
  
  final user = supabase.auth.currentUser;
  if (user == null) {
    debugPrint('FCM 토큰 저장: 로그인된 사용자가 없습니다.');
    return;
  }

  try {
    // iOS 권한 요청 코드 활성화 (주석 해제)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('FCM: 사용자가 알림 권한을 거부했거나 아직 수락하지 않았습니다: ${settings.authorizationStatus}');
      return;
    }
    
    // APNs 토큰 확인 (선택 사항이지만 디버깅에 도움됨)
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    debugPrint('APNs 토큰: $apnsToken');
    
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      debugPrint('FCM 토큰 가져오기 실패');
      return;
    }
    debugPrint('FCM 토큰: $fcmToken');

    // userinfo 테이블에 fcm_token 컬럼에 토큰 저장
    await supabase
        .from('userinfo')
        .update({'fcm_token': fcmToken})
        .eq('id', user.id);

    debugPrint('FCM 토큰 저장 성공 (사용자 ID: ${user.id})');

  } catch (e) {
    // 오류 발생 시 스택 트레이스도 출력하여 더 자세한 정보 확인
    debugPrint('FCM 토큰 저장 중 오류 발생: $e');
    debugPrintStack(); // 스택 트레이스 출력 추가
  }
}

void main() async {
  // Flutter 엔진이 위젯을 바인딩하기 전에 플러그인 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase.initializeApp() 완료됨'); // 완료 로그 추가
  } catch (e) {
    debugPrint('Firebase 초기화 중 오류 발생: $e');
    // 초기화 실패 시 앱 실행 중단 또는 다른 처리 필요
    return;
  }

  // 앱의 화면 방향을 세로 모드로 고정 (상하 반전 포함)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['PROD_SUPABASE_URL']!;
  final supabaseKey = dotenv.env['PROD_SUPABASE_ANON_KEY']!;

  initializeDateFormatting('ko_KR');
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  // await Supabase.instance.client.auth.signOut(); // 개발 중에는 주석 처리하거나 필요에 따라 사용

  // --- 테스트를 위해 리스너 잠시 주석 처리 ---
  // FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  //   debugPrint('FCM 토큰 갱신됨: $newToken');
  //   await saveFcmTokenToSupabase();
  // });
  // ---------------------------------------

  // 앱 시작 시 FCM 토큰 저장 시도 (이 호출에서 오류가 나는지 확인)
  debugPrint('main 함수에서 saveFcmTokenToSupabase() 호출 시도...');
  await saveFcmTokenToSupabase();
  debugPrint('main 함수 내 saveFcmTokenToSupabase() 호출 완료.');

  // 포그라운드 메시지 핸들러 등록
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');
    // 여기서 앱 내 알림 표시 로직 구현 가능
  });

  // 백그라운드/종료 상태에서 알림 클릭 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('알림 클릭으로 앱 열림: ${message.notification?.title}');
    // 여기서 특정 화면으로 이동하는 로직 구현 가능
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNU-PingPong-App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const MyInfoPage(),
        '/profile/edit': (context) => const EditProfilePage(),
        '/change_password': (context) => const ChangePasswordPage(),
        '/signup': (context) => const SignUpPage(),
      },
    );
  }
}
