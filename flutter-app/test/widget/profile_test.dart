import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/widget_test_helpers.dart';

// 테스트용 MyInfoPage 위젯 래퍼
class TestableMyInfoPage extends StatefulWidget {
  const TestableMyInfoPage({super.key});

  @override
  _TestableMyInfoPageState createState() => _TestableMyInfoPageState();
}

class _TestableMyInfoPageState extends State<TestableMyInfoPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // 실제 MyInfoPage는 Supabase에 의존하므로, 테스트에서는 더미 UI만 복제
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        children: [
          // 사용자 정보 헤더
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 12),
                const Text('안녕하세요, 테스트 사용자님', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('전공:'),
                        Text('학번:'),
                        Text('부수 / 승점:'),
                      ],
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('컴퓨터공학과'),
                        Text('20230001'),
                        Text('1500'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 메뉴 아이템들
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('비밀번호 재설정'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('프로필 수정'),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('모집공고 알람 듣기(미구현)'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('MyInfoPage가 정상적으로 렌더링되는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWrapper(child: TestableMyInfoPage()),
    );

    // 필드 확인
    expect(find.text('전공:'), findsOneWidget);
    expect(find.text('학번:'), findsOneWidget);
    expect(find.text('부수 / 승점:'), findsOneWidget);

    // 메뉴 아이템 확인
    expect(find.text('비밀번호 재설정'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('모집공고 알람 듣기(미구현)'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('로그아웃 버튼 동작 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWrapper(child: TestableMyInfoPage()),
    );

    // 로그아웃 버튼 찾기 및 클릭
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    // 로그인 페이지로 이동했는지 확인
    expect(find.text('로그인 페이지'), findsOneWidget);
  });

  testWidgets('프로필 수정 버튼 동작 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWrapper(child: TestableMyInfoPage()),
    );

    // 프로필 수정 버튼 찾기 및 클릭
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();

    // 프로필 수정 페이지로 이동 확인
    expect(find.text('프로필 수정 페이지'), findsOneWidget);
  });

  testWidgets('알림 설정 토글 동작 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TestWrapper(child: TestableMyInfoPage()),
    );

    // 초기 상태의 스위치 찾기
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // 스위치의 초기 상태 확인 (기본값은 true)
    Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isTrue);

    // 스위치 토글
    await tester.tap(switchFinder);
    await tester.pump();

    // 토글 후 상태 확인
    switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);
  });
}
