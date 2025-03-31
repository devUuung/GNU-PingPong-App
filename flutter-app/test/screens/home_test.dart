import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/home.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/widgets/favorite_users_widget.dart';
import 'package:flutter_app/widgets/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

// Supabase 클라이언트 모킹을 위한 클래스들
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGotrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  group('HomePage 화면 테스트', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGotrueClient mockGotrueClient;
    late MockUser mockUser;

    setUp(() {
      // Supabase 모킹 설정
      mockSupabaseClient = MockSupabaseClient();
      mockGotrueClient = MockGotrueClient();
      mockUser = MockUser();

      // 모의 응답 설정
      when(() => mockSupabaseClient.auth).thenReturn(mockGotrueClient);
      when(() => mockGotrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('test-user-id');

      // Supabase.instance.client를 모의 객체로 대체하는 방법은 실제로는 더 복잡합니다.
      // 이 테스트에서는 간단한 예시만 제공합니다.
    });

    testWidgets('HomePage가 올바르게 렌더링되는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );

      // 주요 위젯들이 렌더링되는지 확인
      expect(find.byType(CommonAppBar), findsOneWidget);
      expect(find.byType(CommonBottomNavigationBar), findsOneWidget);
      expect(find.byType(FavoriteUsersWidget), findsOneWidget);
      expect(find.byType(Post), findsOneWidget);

      // 주요 텍스트 요소들이 표시되는지 확인
      expect(find.text('즐겨찾기'), findsOneWidget);
      expect(find.text('모집 공고'), findsOneWidget);
      expect(find.text('글쓰기'), findsOneWidget);
    });

    testWidgets('글쓰기 버튼 클릭 시 네비게이션이 작동하는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성 (네비게이션을 위한 라우트 설정 포함)
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => HomePage(),
            '/post_create': (context) => Scaffold(
                  appBar: AppBar(title: Text('글쓰기 화면')),
                  body: Center(child: Text('글쓰기 화면입니다')),
                ),
          },
        ),
      );

      // 글쓰기 버튼 찾기
      final writeButton = find.text('글쓰기');
      expect(writeButton, findsOneWidget);

      // 글쓰기 버튼 클릭
      await tester.tap(writeButton);
      await tester.pumpAndSettle(); // 애니메이션 완료 대기

      // 글쓰기 화면으로 이동했는지 확인
      expect(find.text('글쓰기 화면'), findsOneWidget);
      expect(find.text('글쓰기 화면입니다'), findsOneWidget);
    });

    testWidgets('스크롤이 올바르게 작동하는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );

      // 스크롤 가능한 위젯 찾기
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // 아래로 스크롤
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pump(); // 프레임 업데이트

      // 스크롤 후에도 주요 요소들이 여전히 존재하는지 확인
      expect(find.byType(CommonAppBar), findsOneWidget);
      expect(find.byType(CommonBottomNavigationBar), findsOneWidget);
    });

    // 참고: 실제 Supabase 연동 테스트는 더 복잡한 모킹이 필요합니다.
    // 아래는 로딩 상태 테스트의 기본 구조만 제공합니다.

    testWidgets('로딩 상태가 올바르게 표시되는지 테스트', (WidgetTester tester) async {
      // 로딩 상태를 가진 HomePage 구현이 필요합니다.
      // 이 테스트는 개념적인 구조만 제공합니다.

      // 로딩 상태를 가진 HomePage 위젯 생성
      final homePage = HomePage();

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: homePage,
        ),
      );

      // 로딩 상태일 때 로딩 인디케이터가 표시되는지 확인
      // 참고: 실제 테스트에서는 로딩 상태를 설정하는 방법이 필요합니다.
      // expect(find.text('데이터를 불러오는 중...'), findsOneWidget);
    });
  });
}
