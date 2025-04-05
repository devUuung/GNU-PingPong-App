import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/login.dart';
import '../utils/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  testWidgets('LoginPage UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const LoginPage()));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.text('로그인'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // 학번, 비밀번호 입력 필드
    expect(find.byType(ElevatedButton), findsOneWidget); // 로그인 버튼
  });

  testWidgets('로그인 버튼 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const LoginPage()));

    // 학번과 비밀번호 입력
    await tester.enterText(find.byType(TextField).first, '12345678');
    await tester.enterText(find.byType(TextField).last, 'password123');

    // 로그인 버튼 클릭
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // 에러 다이얼로그가 표시되는지 확인 (실제 로그인은 실패할 것이므로)
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
