import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setupTestEnvironment() async {
  // Flutter 엔진 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: '.env');

  // shared_preferences 초기화
  SharedPreferences.setMockInitialValues({});

  // Supabase 초기화
  const supabaseUrl = 'https://neyijpnwimzgeszwupzh.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_KEY']!;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
}

// 테스트에서 사용할 공통 위젯 래퍼
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}
