// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnu_pingpong_app/screens/login.dart';
import 'package:gnu_pingpong_app/screens/home.dart';
import 'package:gnu_pingpong_app/screens/profile.dart';
import 'package:gnu_pingpong_app/screens/profile_edit.dart';
import 'package:gnu_pingpong_app/screens/change_password.dart';
import 'package:gnu_pingpong_app/screens/signup.dart';
import 'package:gnu_pingpong_app/utils/version_check.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Flutter 엔진이 위젯을 바인딩하기 전에 플러그인 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 블루투스 플러그인 초기화
  // await FlutterBluetoothSerial.instance;

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
  await Supabase.instance.client.auth.signOut();

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
      builder: (context, child) {
        // 앱 실행 시 버전 체크
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VersionCheck().checkForUpdate(context);
        });
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
