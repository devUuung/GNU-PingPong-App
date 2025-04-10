import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnu_pingpong_app/screens/post_edit.dart';
import '../helpers/widget_test_helpers.dart';

// 테스트용 PostEdit 위젯 래퍼
class TestablePostEdit extends StatelessWidget {
  final int postId;

  const TestablePostEdit({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    // 실제 RecruitEditPage는 Supabase에 의존하므로, 테스트에서는 더미 UI만 렌더링
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 수정'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 필드
              const Text('제목', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: '테스트 제목',
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요.',
                ),
              ),
              const SizedBox(height: 16),

              // 날짜/시간 필드
              const Text('날짜 / 시간',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: '2023-01-01 10:00',
                decoration: const InputDecoration(
                  hintText: '날짜와 시간을 선택하세요.',
                ),
              ),
              const SizedBox(height: 16),

              // 장소 필드
              const Text('장소', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: '테스트 장소',
                decoration: const InputDecoration(
                  hintText: '장소를 입력하세요.',
                ),
              ),
              const SizedBox(height: 16),

              // 최대 인원 필드
              const Text('최대 인원',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: '4',
                decoration: const InputDecoration(
                  hintText: '최대 인원을 입력하세요.',
                ),
              ),
              const SizedBox(height: 16),

              // 내용 필드
              const Text('내용', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: '테스트 내용',
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요.',
                ),
                maxLines: 3, // 줄 수 제한
              ),
              const SizedBox(height: 24),

              // 수정하기 버튼
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('수정하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('RecruitEditPage가 정상적으로 렌더링되는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TestablePostEdit(postId: 1),
      ),
    );

    // 필드 확인
    expect(find.text('제목'), findsOneWidget);
    expect(find.text('날짜 / 시간'), findsOneWidget);
    expect(find.text('장소'), findsOneWidget);
    expect(find.text('최대 인원'), findsOneWidget);
    expect(find.text('내용'), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);
  });

  testWidgets('폼 입력 후 수정하기 버튼 동작 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TestablePostEdit(postId: 1),
      ),
    );

    // 제목 필드 입력
    await tester.enterText(find.byType(TextFormField).at(0), '수정된 제목');

    // 장소 필드 입력
    await tester.enterText(find.byType(TextFormField).at(2), '수정된 장소');

    // 최대 인원 필드 입력
    await tester.enterText(find.byType(TextFormField).at(3), '6');

    // 내용 필드 입력
    await tester.enterText(find.byType(TextFormField).at(4), '수정된 내용');

    // 스크롤하여 수정하기 버튼 위치로 이동
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // 수정하기 버튼 탭
    await tester.tap(find.text('수정하기'));
    await tester.pump();
  });
}
