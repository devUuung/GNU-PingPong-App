import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:postgrest/postgrest.dart';
import 'package:gotrue/gotrue.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  final Map<String, dynamic> _mockData = {};
  final Map<String, Function> _mockFunctions = {};

  @override
  GoTrueClient get auth => MockSupabaseAuthClient();

  @override
  SupabaseQueryBuilder from(String table) {
    return MockSupabaseQueryBuilder(table, _mockData, _mockFunctions);
  }

  void setMockData(String key, dynamic value) {
    _mockData[key] = value;
  }

  void setMockFunction(String key, Function function) {
    _mockFunctions[key] = function;
  }
}

class MockSupabaseAuthClient extends Mock implements GoTrueClient {
  User? _currentUser;
  Session? _currentSession;

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void setCurrentSession(Session session) {
    _currentSession = session;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? captchaToken,
    String? email,
    required String password,
    String? phone,
  }) async {
    if (email == 'test@gnu.ac.kr' && password == 'password123') {
      final user = User(
        id: 'test-user-id',
        email: email ?? '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        appMetadata: {},
        userMetadata: {},
        aud: '',
        role: '',
      );
      _currentUser = user;
      _currentSession = Session(
        accessToken: 'mock-access-token',
        tokenType: 'bearer',
        expiresIn: 3600,
        refreshToken: 'mock-refresh-token',
        user: user,
      );
      return AuthResponse(
        session: _currentSession,
        user: user,
      );
    }
    throw AuthException('Invalid credentials');
  }

  @override
  Future<void> signOut({SignOutScope? scope}) async {
    _currentUser = null;
    _currentSession = null;
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  final String table;
  final Map<String, dynamic> _mockData;
  final Map<String, Function> _mockFunctions;

  MockSupabaseQueryBuilder(this.table, this._mockData, this._mockFunctions);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    final key = '$table:$columns';
    if (_mockData.containsKey(key)) {
      return MockPostgrestFilterBuilder(
          List<Map<String, dynamic>>.from(_mockData[key]));
    }
    return MockPostgrestFilterBuilder([]);
  }

  @override
  PostgrestFilterBuilder<Map<String, dynamic>> single() {
    final key = '$table:single';
    if (_mockData.containsKey(key)) {
      return MockPostgrestFilterBuilder(
          Map<String, dynamic>.from(_mockData[key]));
    }
    throw Exception('No data found');
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool? defaultToNull}) {
    final key = '$table:insert';
    if (_mockFunctions.containsKey(key)) {
      _mockFunctions[key]?.call(values);
    }
    return MockPostgrestFilterBuilder(null);
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Map values) {
    final key = '$table:update';
    if (_mockFunctions.containsKey(key)) {
      _mockFunctions[key]?.call(values);
    }
    return MockPostgrestFilterBuilder(null);
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    final key = '$table:delete';
    if (_mockFunctions.containsKey(key)) {
      _mockFunctions[key]?.call();
    }
    return MockPostgrestFilterBuilder(null);
  }

  @override
  MockSupabaseQueryBuilder eq(String column, dynamic value) {
    return this;
  }

  @override
  MockSupabaseQueryBuilder neq(String column, dynamic value) {
    return this;
  }
}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  final T _value;

  MockPostgrestFilterBuilder(this._value);

  @override
  Future<T> execute() async {
    return _value;
  }
}
