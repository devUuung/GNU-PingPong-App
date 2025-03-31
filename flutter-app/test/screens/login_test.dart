import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/login.dart';
import 'package:flutter_app/screens/signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

// Supabase 클라이언트 모킹을 위한 클래스들
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGotrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  group('LoginPage 화면 테스트', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGotrueClient mockGotrueClient;
    late MockAuthResponse mockAuthResponse;
    late MockSession mockSession;

    setUp(() {
      // Supabase 모킹 설정
      mockSupabaseClient = MockSupabaseClient();
      mockGotrueClient = MockGotrueClient();
      mockAuthResponse = MockAuthResponse();
      mockSession = MockSession();

      // 모의 응답 설정
      when(() => mockSupabaseClient.auth).thenReturn(mockGotrueClient);
      when(() => mockGotrueClient.currentSession).thenReturn(null);
      when(() => mockGotrueClient.signOut()).thenAnswer((_) => Future.value());

      // Supabase.instance.client를 모의 객체로 대체하는 방법은 실제로는 더 복잡합니다.
      // 이 테스트에서는 간단한 예시만 제공합니다.
    });

    testWidgets('LoginPage가 올바르게 렌더링되는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 로그인 화면의 주요 요소들이 표시되는지 확인
      expect(find.text('로그인'), findsOneWidget);
      expect(find.text('학번'), findsOneWidget);
      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('회원가입하기'), findsOneWidget);

      // 텍스트 필드가 있는지 확인
      expect(find.byType(TextField), findsNWidgets(2));

      // 로그인 버튼이 있는지 확인
      expect(find.widgetWithText(ElevatedButton, '로그인'), findsOneWidget);
    });

    testWidgets('학번과 비밀번호 입력 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 학번 입력
      await tester.enterText(find.widgetWithText(TextField, '학번'), '20230001');

      // 비밀번호 입력
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호'), 'password123');

      // 입력된 값 확인
      expect(find.text('20230001'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('로그인 버튼 클릭 테스트 - 성공 케이스', (WidgetTester tester) async {
      // 로그인 성공 모킹
      when(() => mockGotrueClient.signInWithPassword(
            email: '20230001',
            password: 'password123',
          )).thenAnswer((_) async {
        when(() => mockAuthResponse.session).thenReturn(mockSession);
        return mockAuthResponse;
      });

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 학번 입력
      await tester.enterText(find.widgetWithText(TextField, '학번'), '20230001');

      // 비밀번호 입력
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호'), 'password123');

      // 로그인 버튼 클릭
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pump();

      // 로딩 인디케이터가 표시되는지 확인
      expect(find.text('로그인 중...'), findsOneWidget);

      // 로그인 성공 후 HomePage로 이동하는지 확인
      // 참고: 실제 테스트에서는 네비게이션 테스트를 위한 추가 설정이 필요할 수 있습니다.
    });

    testWidgets('로그인 버튼 클릭 테스트 - 실패 케이스', (WidgetTester tester) async {
      // 로그인 실패 모킹
      when(() => mockGotrueClient.signInWithPassword(
            email: '20230001',
            password: 'wrong_password',
          )).thenAnswer((_) async {
        when(() => mockAuthResponse.session).thenReturn(null);
        return mockAuthResponse;
      });

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 학번 입력
      await tester.enterText(find.widgetWithText(TextField, '학번'), '20230001');

      // 잘못된 비밀번호 입력
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호'), 'wrong_password');

      // 로그인 버튼 클릭
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pump();

      // 로딩 인디케이터가 표시되는지 확인
      expect(find.text('로그인 중...'), findsOneWidget);

      // 로그인 실패 후 에러 다이얼로그가 표시되는지 확인
      // 참고: 실제 테스트에서는 다이얼로그 테스트를 위한 추가 설정이 필요할 수 있습니다.
    });

    testWidgets('회원가입하기 버튼 클릭 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 회원가입하기 버튼 클릭
      await tester.tap(find.text('회원가입하기'));
      await tester.pumpAndSettle();

      // SignUpPage로 이동했는지 확인
      expect(find.byType(SignUpPage), findsOneWidget);
    });
  });
}
