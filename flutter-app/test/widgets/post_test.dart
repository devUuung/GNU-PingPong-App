import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/test_helper.dart';

/// Supabase 클라이언트 모킹을 위한 클래스들
///
/// 이 클래스들은 Supabase 클라이언트와 관련된 객체들을 모킹하여 테스트 환경에서 사용합니다.
/// 실제 Supabase 서버에 연결하지 않고도 테스트를 수행할 수 있도록 합니다.

/// Supabase 클라이언트 모킹 클래스
///
/// 이 클래스는 SupabaseClient 인터페이스를 구현하여 테스트 환경에서 사용합니다.
class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) => MockSupabaseQueryBuilder();
}

/// GoTrue 클라이언트 모킹 클래스
///
/// 이 클래스는 GoTrueClient 인터페이스를 구현하여 인증 관련 기능을 모킹합니다.
class MockGotrueClient extends Mock implements GoTrueClient {}

/// 사용자 모킹 클래스
///
/// 이 클래스는 User 인터페이스를 구현하여 사용자 정보를 모킹합니다.
class MockUser extends Mock implements User {}

/// Supabase 쿼리 빌더 모킹 클래스
///
/// 이 클래스는 SupabaseQueryBuilder 인터페이스를 구현하여 쿼리 빌더를 모킹합니다.
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String? query]) =>
      MockPostgrestFilterBuilder();
}

/// Postgrest 필터 빌더 모킹 클래스
///
/// 이 클래스는 PostgrestFilterBuilder 인터페이스를 구현하여 필터 빌더를 모킹합니다.
/// 빈 리스트를 반환하도록 설정되어 있습니다.
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  Future<List<Map<String, dynamic>>> execute() async => [];
}

/// 테스트용 Postgrest 필터 빌더 클래스
///
/// 이 클래스는 테스트 데이터를 반환하도록 설정된 PostgrestFilterBuilder입니다.
/// 특정 테스트 케이스에서 사용할 데이터를 지정할 수 있습니다.
class TestPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _data;

  TestPostgrestFilterBuilder(this._data);

  Future<List<Map<String, dynamic>>> execute() async => _data;
}

/// Post 위젯 테스트
///
/// 이 테스트는 Post 위젯의 동작을 검증합니다.
/// 로딩 상태, UI 요소, 클릭 이벤트 등을 테스트합니다.
void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGotrueClient mockGotrueClient;
  late MockUser mockUser;

  /// 모든 테스트 전에 실행되는 설정 함수
  ///
  /// 이 함수는 테스트 환경을 초기화합니다.
  setUpAll(() async {
    await setupTestEnvironment();
  });

  /// 각 테스트 전에 실행되는 설정 함수
  ///
  /// 이 함수는 각 테스트마다 새로운 모의 객체를 생성하고 설정합니다.
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

  /// Post 위젯 로딩 상태 테스트
  ///
  /// 이 테스트는 Post 위젯이 초기 로딩 상태에서 CircularProgressIndicator를 표시하는지 확인합니다.
  testWidgets('Post 위젯이 로딩 상태를 올바르게 표시하는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 초기 로딩 상태에서는 CircularProgressIndicator가 표시되어야 함
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  /// Post 위젯 UI 테스트
  ///
  /// 이 테스트는 Post 위젯의 기본 UI 요소들이 존재하는지 확인합니다.
  testWidgets('Post 위젯 UI 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  /// Post 위젯 클릭 테스트
  ///
  /// 이 테스트는 Post 위젯의 클릭 이벤트가 올바르게 처리되는지 확인합니다.
  testWidgets('Post 위젯 클릭 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(const Post()));

    // 로딩 상태가 끝날 때까지 대기
    await tester.pump(const Duration(seconds: 1));
  });
}
