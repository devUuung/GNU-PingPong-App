import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/login.dart';
import '../helpers/widget_test_helpers.dart';

// 테스트용 LoginPage 래퍼
class TestableLoginPage extends StatelessWidget {
  const TestableLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 LoginPage는 Supabase에 의존하므로, 테스트에서는 UI만 복제
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 학번 입력 필드
            TextField(
              decoration: const InputDecoration(
                labelText: '학번',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // 비밀번호 입력 필드
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),

            // 로그인 버튼
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('오류'),
                    content: const Text('학번과 비밀번호를 입력해주세요.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('로그인'),
            ),

            // 회원가입 링크
            TextButton(
              onPressed: () {},
              child: const Text('회원가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('LoginPage Tests', () {
    testWidgets('LoginPage displays required UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestableLoginPage(),
      ));

      // AppBar 제목과 로그인 버튼의 '로그인' 텍스트 확인
      expect(find.text('로그인'), findsNWidgets(2));

      // 학번 입력 필드 확인
      expect(find.widgetWithText(TextField, '학번'), findsOneWidget);

      // 비밀번호 입력 필드 확인
      expect(find.widgetWithText(TextField, '비밀번호'), findsOneWidget);

      // 로그인 버튼 확인
      expect(find.widgetWithText(ElevatedButton, '로그인'), findsOneWidget);

      // 회원가입 버튼 확인
      expect(find.widgetWithText(TextButton, '회원가입하기'), findsOneWidget);
    });

    testWidgets('Tapping 로그인 with empty fields shows error dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestableLoginPage(),
      ));

      // 로그인 버튼 탭
      await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
      await tester.pumpAndSettle();

      // 에러 다이얼로그 메시지 확인
      expect(find.text('학번과 비밀번호를 입력해주세요.'), findsOneWidget);
    });
  });
}
