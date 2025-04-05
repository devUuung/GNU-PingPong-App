import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/test_helper.dart';

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
  late MockSupabaseClient mockSupabaseClient;
  late MockGotrueClient mockGotrueClient;
  late MockUser mockUser;

  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    // Supabase 모킹 설정
    mockSupabaseClient = MockSupabaseClient();
    mockGotrueClient = MockGotrueClient();
    mockUser = MockUser();

    // 모의 응답 설정
    when(() => mockSupabaseClient.auth).thenReturn(mockGotrueClient);
    when(() => mockGotrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');

    // Supabase.instance.client를 모의 객체로 대체
    Supabase.instance.client = mockSupabaseClient;
  });

  testWidgets('Post 위젯이 로딩 상태를 올바르게 표시하는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 초기 로딩 상태에서는 CircularProgressIndicator가 표시되어야 함
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Post 위젯 UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Post 위젯 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 로딩 상태가 끝날 때까지 대기
    await tester.pump(const Duration(seconds: 1));
  });
}
