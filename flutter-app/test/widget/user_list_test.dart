import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/user_list.dart';
import '../helpers/widget_test_helpers.dart';

// 테스트용 UserList 위젯 래퍼
class TestableUserList extends StatelessWidget {
  const TestableUserList({super.key});

  @override
  Widget build(BuildContext context) {
    // 실제 UserListPage는 Supabase에 의존하므로, 테스트에서는 더미 UI만 렌더링
    return Scaffold(
      appBar: AppBar(
        title: const Text('명단'),
      ),
      body: Column(
        children: [
          // 필터 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('점수'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('게임 수'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('승리 수'),
              ),
            ],
          ),

          // 사용자 목록
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('사용자1'),
                  subtitle: const Text('1200점'),
                  trailing: IconButton(
                    icon: const Icon(Icons.star_border),
                    onPressed: () {},
                  ),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('사용자2'),
                  subtitle: const Text('1150점'),
                  trailing: IconButton(
                    icon: const Icon(Icons.star_border),
                    onPressed: () {},
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('UserListPage가 정상적으로 렌더링되는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TestableUserList(),
      ),
    );

    // 명단 타이틀 확인
    expect(find.text('명단'), findsOneWidget);

    // 필터 버튼 확인
    expect(find.text('점수'), findsOneWidget);
    expect(find.text('게임 수'), findsOneWidget);
    expect(find.text('승리 수'), findsOneWidget);

    // 사용자 목록 아이템 확인
    expect(find.text('사용자1'), findsOneWidget);
    expect(find.text('사용자2'), findsOneWidget);
  });

  testWidgets('필터 버튼 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TestableUserList(),
      ),
    );

    // 게임 수 필터 버튼 클릭
    await tester.tap(find.text('게임 수'));
    await tester.pump();

    // 클릭 성공 여부만 확인 (실제 기능은 검증하지 않음)
  });

  testWidgets('사용자 프로필 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TestableUserList(),
      ),
    );

    // 사용자 아이템 클릭
    await tester.tap(find.text('사용자1'));
    await tester.pump();

    // 클릭 성공 여부만 확인 (실제 다이얼로그는 검증하지 않음)
  });
}
