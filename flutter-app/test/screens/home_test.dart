import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/home.dart';
import '../utils/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  testWidgets('HomePage UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const HomePage()));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.text('경상탁구가족'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('게시글 목록 로딩 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const HomePage()));
    await tester.pumpAndSettle();

    // 로딩 인디케이터가 표시되는지 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
