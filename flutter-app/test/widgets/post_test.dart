import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/post.dart';
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
  Future<List<Map<String, dynamic>>> execute() async => [];
}

class TestPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _data;

  TestPostgrestFilterBuilder(this._data);

  Future<List<Map<String, dynamic>>> execute() async => _data;
}

void main() {
  group('Post 위젯 테스트', () {
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

    testWidgets('Post 위젯이 로딩 상태를 올바르게 표시하는지 테스트', (WidgetTester tester) async {
      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Post(),
          ),
        ),
      );

      // 초기 로딩 상태에서는 CircularProgressIndicator가 표시되어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // 참고: 실제 Supabase 연동 테스트는 더 복잡한 모킹이 필요합니다.
    // 아래는 모킹을 사용한 테스트의 기본 구조만 제공합니다.

    testWidgets('게시물이 없을 때 적절한 메시지를 표시하는지 테스트', (WidgetTester tester) async {
      // 빈 게시물 목록 반환하도록 모킹
      when(() => mockSupabaseClient.from('post').select())
          .thenReturn(TestPostgrestFilterBuilder([]));

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Post(),
          ),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // "모집공고가 없습니다." 메시지가 표시되어야 함
      expect(find.text('모집공고가 없습니다.'), findsOneWidget);
    });

    // 참고: 아래 테스트는 실제 Supabase 연동 환경에서는 더 복잡한 모킹이 필요합니다.
    // 이 테스트 코드는 개념적인 구조만 제공하며, 실제 구현에서는 추가 작업이 필요할 수 있습니다.

    testWidgets('게시물 목록이 올바르게 표시되는지 테스트', (WidgetTester tester) async {
      // 테스트용 게시물 데이터
      final testPosts = [
        {
          'post_id': 1,
          'title': '테스트 게시물',
          'content': '테스트 내용입니다.',
          'writer_id': 'test-user-id',
          'game_at': '2023-01-01T14:00:00.000Z',
          'game_place': '테스트 장소',
          'max_user': 4,
        },
        {
          'post_id': 2,
          'title': '다른 게시물',
          'content': '다른 내용입니다.',
          'writer_id': 'other-user-id',
          'game_at': '2023-01-02T15:00:00.000Z',
          'game_place': '다른 장소',
          'max_user': 6,
        },
      ];

      // 게시물 목록 반환하도록 모킹
      when(() => mockSupabaseClient.from('post').select())
          .thenReturn(TestPostgrestFilterBuilder(testPosts));

      // 테스트를 위한 위젯 트리 구성
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Post(),
          ),
        ),
      );

      // 로딩 상태가 끝난 후 위젯 업데이트
      await tester.pump(const Duration(seconds: 1));

      // 게시물 제목이 표시되는지 확인
      expect(find.text('테스트 게시물'), findsOneWidget);
      expect(find.text('다른 게시물'), findsOneWidget);

      // 게시물 내용이 표시되는지 확인
      expect(find.text('테스트 내용입니다.'), findsOneWidget);
      expect(find.text('다른 내용입니다.'), findsOneWidget);

      // 작성자인 게시물에는 수정/삭제 버튼이 표시되어야 함
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);

      // 참가자가 아닌 게시물에는 참여하기 버튼이 표시되어야 함
      expect(find.text('참여하기'), findsOneWidget);
    });
  });
}
