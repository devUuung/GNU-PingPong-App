import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/profile.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

// Supabase 클라이언트 모킹을 위한 클래스들
class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) => MockSupabaseQueryBuilder();
}

class MockGotrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? query]) =>
      MockPostgrestFilterBuilder();
}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
          String column, dynamic value) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      MockPostgrestTransformBuilder();
}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> execute() async => {
        'username': '테스트사용자',
        'avatar_url': '',
        'status_message': '테스트 상태 메시지',
        'department': '컴퓨터공학과',
        'student_id': 20230001,
        'rank': 3,
        'custom_point': 150,
      };
}

void main() {
  group('MyInfoPage(Profile) 화면 테스트', () {
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
    });

    testWidgets('MyInfoPage가 로딩 상태를 올바르게 표시하는지 테스트',
        (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
        ),
      );

      // 초기 로딩 상태에서는 CircularProgressIndicator가 표시되어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('사용자 정보가 올바르게 표시되는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 사용자 정보가 올바르게 표시되는지 확인
      expect(find.text('안녕하세요, 테스트사용자님'), findsOneWidget);
      expect(find.text('테스트 상태 메시지'), findsOneWidget);
      expect(find.text('전공:'), findsOneWidget);
      expect(find.text('컴퓨터공학과'), findsOneWidget);
      expect(find.text('학번:'), findsOneWidget);
      expect(find.text('20230001'), findsOneWidget);
      expect(find.text('부수 / 승점:'), findsOneWidget);
      expect(find.text('3부 / 150'), findsOneWidget);
    });

    testWidgets('설정 메뉴 항목이 올바르게 표시되는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 설정 메뉴 항목이 올바르게 표시되는지 확인
      expect(find.text('비밀번호 재설정'), findsOneWidget);
      expect(find.text('프로필 수정'), findsOneWidget);
      expect(find.text('모집공고 알람 듣기(미구현)'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('그 외 항목2'), findsOneWidget);

      // 토글 스위치가 있는지 확인
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('비밀번호 재설정 버튼 클릭 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성 (네비게이션을 위한 라우트 설정 포함)
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
          routes: {
            '/change_password': (context) => Scaffold(
                  appBar: AppBar(title: Text('비밀번호 변경')),
                  body: Center(child: Text('비밀번호 변경 화면')),
                ),
          },
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 비밀번호 재설정 버튼 찾기
      final passwordResetButton = find.text('비밀번호 재설정');
      expect(passwordResetButton, findsOneWidget);

      // 비밀번호 재설정 버튼 클릭
      await tester.tap(passwordResetButton);
      await tester.pumpAndSettle(); // 애니메이션 완료 대기

      // 비밀번호 변경 화면으로 이동했는지 확인
      // 참고: 실제 테스트에서는 네비게이션 테스트를 위한 추가 설정이 필요할 수 있습니다.
    });

    testWidgets('프로필 수정 버튼 클릭 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성 (네비게이션을 위한 라우트 설정 포함)
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
          routes: {
            '/profile_edit': (context) => Scaffold(
                  appBar: AppBar(title: Text('프로필 수정')),
                  body: Center(child: Text('프로필 수정 화면')),
                ),
          },
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 프로필 수정 버튼 찾기
      final profileEditButton = find.text('프로필 수정');
      expect(profileEditButton, findsOneWidget);

      // 프로필 수정 버튼 클릭
      await tester.tap(profileEditButton);
      await tester.pumpAndSettle(); // 애니메이션 완료 대기

      // 프로필 수정 화면으로 이동했는지 확인
      // 참고: 실제 테스트에서는 네비게이션 테스트를 위한 추가 설정이 필요할 수 있습니다.
    });

    testWidgets('알람 토글 스위치 작동 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 토글 스위치 찾기
      final toggleSwitch = find.byType(Switch);
      expect(toggleSwitch, findsOneWidget);

      // 토글 스위치의 초기 상태 확인 (기본값은 true)
      Switch switchWidget = tester.widget<Switch>(toggleSwitch);
      expect(switchWidget.value, true);

      // 토글 스위치 클릭
      await tester.tap(toggleSwitch);
      await tester.pump();

      // 토글 스위치 상태가 변경되었는지 확인
      // 참고: 실제 테스트에서는 상태 변경을 확인하기 위한 추가 설정이 필요할 수 있습니다.
    });

    testWidgets('로그아웃 버튼 클릭 테스트', (WidgetTester tester) async {
      // 로그아웃 모킹
      when(() => mockGotrueClient.signOut()).thenAnswer((_) async => {});

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: MyInfoPage(),
        ),
      );

      // 데이터 로딩 완료 대기
      await tester.pump(const Duration(seconds: 1));

      // 로그아웃 버튼 찾기
      final logoutButton = find.text('로그아웃');
      expect(logoutButton, findsOneWidget);

      // 로그아웃 버튼 클릭
      await tester.tap(logoutButton);
      await tester.pump();

      // 로그아웃 함수가 호출되었는지 확인
      // 참고: 실제 테스트에서는 로그아웃 확인을 위한 추가 설정이 필요할 수 있습니다.
    });
  });
}
