import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/screens/home.dart';
import 'package:flutter_app/screens/user_list.dart';
import 'package:flutter_app/screens/games.dart';
import 'package:flutter_app/screens/profile.dart';
import '../utils/test_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  group('CommonBottomNavigationBar 위젯 테스트', () {
    testWidgets('CommonBottomNavigationBar가 올바르게 렌더링되는지 테스트',
        (WidgetTester tester) async {
      // CommonBottomNavigationBar 위젯을 MaterialApp 내에서 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CommonBottomNavigationBar(
              currentPage: 'home',
            ),
          ),
        ),
      );

      // 네비게이션 바 아이템들이 올바르게 표시되는지 확인
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('회원목록'), findsOneWidget);
      expect(find.text('경기기록'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);

      // 아이콘들이 올바르게 표시되는지 확인
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('currentPage에 따라 올바른 탭이 선택되는지 테스트',
        (WidgetTester tester) async {
      // 각 페이지별로 테스트
      final testCases = [
        {'page': 'home', 'index': 0, 'label': '홈'},
        {'page': 'userList', 'index': 1, 'label': '회원목록'},
        {'page': 'gameRecord', 'index': 2, 'label': '경기기록'},
        {'page': 'settings', 'index': 3, 'label': '설정'},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CommonBottomNavigationBar(
                currentPage: testCase['page'] as String,
              ),
            ),
          ),
        );

        // BottomNavigationBar 찾기
        final bottomNavBar = tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar));

        // 현재 선택된 인덱스가 올바른지 확인
        expect(bottomNavBar.currentIndex, testCase['index']);

        // 선택된 탭의 라벨이 올바른지 확인
        expect(find.text(testCase['label'] as String), findsOneWidget);
      }
    });

    // 네비게이션 테스트는 모킹이 필요하므로 Supabase 연동을 고려하여 작성
    testWidgets('탭 클릭 시 네비게이션이 올바르게 작동하는지 테스트', (WidgetTester tester) async {
      // 현재 페이지가 'home'인 상태에서 시작
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CommonBottomNavigationBar(
              currentPage: 'home',
            ),
          ),
        ),
      );

      // 회원목록 탭 클릭
      await tester.tap(find.text('회원목록'));
      await tester.pumpAndSettle();

      // UserListPage로 이동했는지 확인
      expect(find.byType(UserListPage), findsOneWidget);

      // 경기기록 탭 클릭
      await tester.tap(find.text('경기기록'));
      await tester.pumpAndSettle();

      // GamesPage로 이동했는지 확인
      expect(find.byType(GamesPage), findsOneWidget);

      // 설정 탭 클릭
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      // MyInfoPage로 이동했는지 확인
      expect(find.byType(MyInfoPage), findsOneWidget);

      // 홈 탭 클릭
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      // HomePage로 이동했는지 확인
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('현재 페이지와 동일한 탭 클릭 시 네비게이션이 발생하지 않는지 테스트',
        (WidgetTester tester) async {
      // 현재 페이지가 'home'인 상태에서 시작
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const HomePage(),
            bottomNavigationBar: CommonBottomNavigationBar(
              currentPage: 'home',
            ),
          ),
        ),
      );

      // 홈 탭 클릭 (현재 페이지와 동일)
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();

      // 여전히 HomePage에 있는지 확인
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  testWidgets('CommonBottomNavigationBar UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      const CommonBottomNavigationBar(currentPage: "home"),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
  });

  testWidgets('CommonBottomNavigationBar 네비게이션 테스트',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      const CommonBottomNavigationBar(currentPage: "home"),
    ));

    // 프로필 탭 클릭
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // 명단 탭 클릭
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
  });
}
