import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/post_create.dart';

void main() {
  testWidgets('PostCreatePage가 정상적으로 렌더링되는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostCreatePage(),
      ),
    );

    // 앱바 타이틀 확인
    expect(find.text('게시글 작성'), findsOneWidget);

    // 폼 필드들 확인
    expect(find.text('제목'), findsOneWidget);
    expect(find.text('내용'), findsOneWidget);

    // 작성 버튼 확인
    expect(find.text('작성'), findsOneWidget);
  });

  testWidgets('폼 입력 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostCreatePage(),
      ),
    );

    // 제목 필드 입력
    await tester.enterText(
        find.widgetWithText(TextField, '제목을 입력하세요.'), '테스트 제목');

    // 내용 필드 입력
    await tester.enterText(
        find.widgetWithText(TextField, '내용을 입력하세요.'), '테스트 내용');

    // 입력된 텍스트 확인
    expect(find.text('테스트 제목'), findsOneWidget);
    expect(find.text('테스트 내용'), findsOneWidget);
  });

  testWidgets('유효성 검사 테스트 - 빈 양식 제출', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostCreatePage(),
      ),
    );

    // 빈 양식으로 작성 버튼 탭
    await tester.tap(find.text('작성'));
    await tester.pumpAndSettle();

    // 에러 메시지가 표시되어야 함
    expect(find.text('제목과 내용을 입력해주세요.'), findsOneWidget);
  });
}
