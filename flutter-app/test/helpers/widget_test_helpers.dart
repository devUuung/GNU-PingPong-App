import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 모의 Supabase 클래스들
class MockSupabaseClient extends Mock implements SupabaseClient {
  final MockAuthClient _auth = MockAuthClient();

  @override
  GoTrueClient get auth => _auth;
}

class MockAuthClient extends Mock implements GoTrueClient {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  void setCurrentUser(User user) {
    _currentUser = user;
  }
}

// 테스트 래퍼 위젯
class TestWrapper extends StatelessWidget {
  final Widget child;

  const TestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
      // 필요한 라우트 추가
      routes: {
        '/login': (context) => const Scaffold(body: Text('로그인 페이지')),
        '/edit-profile': (context) => const Scaffold(body: Text('프로필 수정 페이지')),
      },
    );
  }
}

// 테스트 유틸리티 함수
Future<void> pumpWidgetWithSafeWait(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(TestWrapper(child: widget));

  // 지정된 시간만 대기 (pumpAndSettle 대신)
  await tester.pump(const Duration(milliseconds: 100));
}
