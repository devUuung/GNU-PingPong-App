import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테스트 환경을 설정하는 함수
///
/// 이 함수는 테스트 실행 전에 호출되어 필요한 초기화 작업을 수행합니다:
/// 1. Flutter 엔진 초기화
/// 2. 환경 변수 로드
/// 3. SharedPreferences 모킹
/// 4. Supabase 클라이언트 초기화
Future<void> setupTestEnvironment() async {
  // Flutter 엔진 초기화 - 테스트 환경에서 위젯을 렌더링하기 위해 필요
  TestWidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 - 환경 변수(API 키 등)를 로드
  await dotenv.load(fileName: '.env');

  // shared_preferences 초기화 - 로컬 저장소를 모킹하여 테스트 환경에서 사용
  SharedPreferences.setMockInitialValues({});

  // Supabase 초기화 - 백엔드 서비스 연결을 위한 클라이언트 초기화
  const supabaseUrl = 'https://neyijpnwimzgeszwupzh.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_KEY']!;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
}

/// 테스트에서 사용할 공통 위젯 래퍼
///
/// 이 함수는 테스트할 위젯을 MaterialApp과 Scaffold로 감싸서 제공합니다.
/// 이를 통해 위젯이 실제 앱 환경과 유사한 컨텍스트에서 테스트될 수 있습니다.
///
/// [child] - 테스트할 위젯
///
/// 반환값: MaterialApp과 Scaffold로 감싸진 위젯
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}
