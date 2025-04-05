import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/profile.dart';
import '../utils/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  testWidgets('MyInfoPage UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const MyInfoPage()));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('사용자 정보 로딩 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const MyInfoPage()));
    await tester.pumpAndSettle();

    // 로딩 인디케이터가 표시되는지 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('프로필 수정 버튼 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const MyInfoPage()));
    await tester.pumpAndSettle();

    // 프로필 수정 버튼 찾기
    final editButton = find.text('프로필 수정');
    expect(editButton, findsOneWidget);

    // 버튼 클릭
    await tester.tap(editButton);
    await tester.pumpAndSettle();
  });
}
