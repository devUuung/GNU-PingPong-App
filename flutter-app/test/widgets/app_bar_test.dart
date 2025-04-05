import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/screens/alarm.dart';
import '../utils/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('CommonAppBar 위젯 테스트', () {
    testWidgets('CommonAppBar가 올바르게 렌더링되는지 테스트', (WidgetTester tester) async {
      // CommonAppBar 위젯을 MaterialApp 내에서 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CommonAppBar(
              currentPage: 'home',
            ),
          ),
        ),
      );

      // 앱바 타이틀이 올바르게 표시되는지 확인
      expect(find.text('경상탁구가족'), findsOneWidget);

      // 알림 아이콘이 기본적으로 표시되는지 확인
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('알림 아이콘이 showNotificationIcon=false일 때 표시되지 않는지 테스트',
        (WidgetTester tester) async {
      // showNotificationIcon을 false로 설정하여 CommonAppBar 위젯 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CommonAppBar(
              currentPage: 'home',
              showNotificationIcon: false,
            ),
          ),
        ),
      );

      // 앱바 타이틀은 여전히 표시되는지 확인
      expect(find.text('경상탁구가족'), findsOneWidget);

      // 알림 아이콘이 표시되지 않는지 확인
      expect(find.byIcon(Icons.notifications), findsNothing);
    });

    testWidgets('알림 아이콘 클릭 시 AlarmPage로 이동하는지 테스트',
        (WidgetTester tester) async {
      // CommonAppBar 위젯을 MaterialApp 내에서 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CommonAppBar(
              currentPage: 'home',
            ),
          ),
        ),
      );

      // 알림 아이콘 찾기
      final notificationIcon = find.byIcon(Icons.notifications);
      expect(notificationIcon, findsOneWidget);

      // 알림 아이콘 클릭
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle(); // 애니메이션 완료 대기

      // AlarmPage로 이동했는지 확인 (AlarmPage 위젯이 렌더링되었는지 확인)
      expect(find.byType(AlarmPage), findsOneWidget);
    });

    testWidgets('preferredSize가 kToolbarHeight와 동일한지 테스트',
        (WidgetTester tester) async {
      // CommonAppBar 인스턴스 생성
      final appBar = CommonAppBar(currentPage: 'home');

      // preferredSize가 kToolbarHeight와 동일한지 확인
      expect(
          appBar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));
    });
  });

  testWidgets('CommonAppBar UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      const CommonAppBar(
        currentPage: "home",
        showNotificationIcon: true,
      ),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);
  });

  testWidgets('CommonAppBar 알림 아이콘 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      const CommonAppBar(
        currentPage: "home",
        showNotificationIcon: true,
      ),
    ));

    // 알림 아이콘 클릭
    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();
  });
}
