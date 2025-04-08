import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks/mock_supabase_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('앱 통합 테스트', () {
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
    });

    testWidgets('전체 앱 플로우 테스트', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Provider로 mock client 주입
      await tester.pumpWidget(
        Provider<SupabaseClient>.value(
          value: mockSupabaseClient,
          child: const MaterialApp(home: app.MyApp()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 로그인 화면에서 시작
      expect(find.text('로그인'), findsOneWidget);

      // 2. 로그인 수행
      await tester.enterText(
          find.byType(TextFormField).first, 'test@gnu.ac.kr');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 3. 홈 화면으로 이동 확인
      expect(find.text('경상탁구가족'), findsOneWidget);

      // 4. 게시글 작성 테스트
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '테스트 게시글');
      await tester.enterText(find.byType(TextFormField).last, '테스트 내용');
      await tester.tap(find.text('작성'));
      await tester.pumpAndSettle();

      // 5. 게시글 목록에서 새 게시글 확인
      expect(find.text('테스트 게시글'), findsOneWidget);

      // 6. 프로필 화면 이동
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // 7. 프로필 편집
      await tester.tap(find.text('프로필 편집'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '새로운 닉네임');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // 8. 로그아웃
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // 9. 로그인 화면으로 돌아왔는지 확인
      expect(find.text('로그인'), findsOneWidget);
    });
  });
}
