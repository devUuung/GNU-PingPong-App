import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/post_create.dart';

// Supabase 모의 설정 또는 테스트 환경 설정 필요 (만약 Supabase 호출이 있다면)
// 예: https://github.com/supabase/supabase-flutter#testing-with-fakesupabase

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
    expect(find.text('장소'), findsOneWidget);
    expect(find.text('최대 인원'), findsOneWidget);

    // 작성 버튼 확인
    expect(find.widgetWithText(ElevatedButton, '작성'), findsOneWidget);
  });

  testWidgets('폼 입력 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostCreatePage(),
      ),
    );

    // 제목 필드 입력
    await tester.enterText(
        find.widgetWithText(TextFormField, '제목을 입력하세요.'), '테스트 제목');

    // 내용 필드 입력
    await tester.enterText(
        find.widgetWithText(TextFormField, '내용을 입력하세요.'), '테스트 내용');

    // 장소 필드 입력
    await tester.enterText(
        find.widgetWithText(TextFormField, '예: 체육관, 제1학생회관 탁구장 등'), '테스트 장소');

    // 최대 인원 필드 입력
    await tester.enterText(
        find.widgetWithText(TextFormField, '본인 포함 최대 인원 (숫자만 입력)'), '4');

    // 입력된 텍스트 확인
    expect(find.text('테스트 제목'), findsOneWidget);
    expect(find.text('테스트 내용'), findsOneWidget);
    expect(find.text('테스트 장소'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('유효성 검사 테스트 - 빈 양식 제출', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostCreatePage(),
      ),
    );

    // '작성' 버튼 찾기
    final submitButton = find.widgetWithText(ElevatedButton, '작성');
    expect(submitButton, findsOneWidget);

    // 버튼이 화면에 보이도록 스크롤 (Hit Test Warning 해결)
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle(); // 스크롤 애니메이션 기다림

    // 빈 양식으로 작성 버튼 탭
    await tester.tap(submitButton);
    // validator가 실행되고 UI가 업데이트될 시간을 줌
    await tester.pump(); // pumpAndSettle() 대신 pump 사용

    // showErrorDialog 메시지 대신 각 TextFormField의 validator 에러 메시지 확인 (TestFailure 해결)
    expect(find.text('제목을 입력해주세요.'), findsOneWidget);
    expect(find.text('내용을 입력해주세요.'), findsOneWidget);
    expect(find.text('장소를 입력해주세요.'), findsOneWidget);
    expect(find.text('최대 인원을 입력해주세요.'), findsOneWidget);
  });
}
