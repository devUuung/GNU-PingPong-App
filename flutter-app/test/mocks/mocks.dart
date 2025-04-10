import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:mockito/mockito.dart' as mockito;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:gotrue/gotrue.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';

// ---------- Mocktail 기반 모킹 클래스 ----------

// Supabase 클래스 모킹
class MockSupabase with mocktail.Mock {
  final MockSupabaseClient clientInstance;

  MockSupabase() : clientInstance = MockSupabaseClient();

  SupabaseClient get client => clientInstance;
}

// SupabaseClient 모킹 (Mocktail)
class MockSupabaseClient with mocktail.Mock implements SupabaseClient {}

// GoTrueClient 모킹 (Mocktail)
class MockGoTrueClient with mocktail.Mock implements GoTrueClient {}

// User 모킹 (Mocktail)
class MockUser with mocktail.Mock implements User {}

// PostgrestClient 모킹 (Mocktail)
class MockPostgrestClient with mocktail.Mock implements PostgrestClient {
  // select 메서드 구현
  PostgrestFilterBuilder<T> select<T>([String columns = '*']) {
    return MockPostgrestFilterBuilder<T>();
  }

  // insert 메서드 구현
  PostgrestFilterBuilder<T> insert<T>(dynamic value) {
    return MockPostgrestFilterBuilder<T>();
  }

  // update 메서드 구현
  PostgrestFilterBuilder<T> update<T>(dynamic value) {
    return MockPostgrestFilterBuilder<T>();
  }

  // delete 메서드 구현
  PostgrestFilterBuilder<T> delete<T>() {
    return MockPostgrestFilterBuilder<T>();
  }
}

// PostgrestFilterBuilder 모킹 (Mocktail)
class MockPostgrestFilterBuilder<T>
    with mocktail.Mock
    implements PostgrestFilterBuilder<T> {
  // eq 메서드 구현
  PostgrestFilterBuilder<T> eq(String column, dynamic value) {
    return this;
  }

  // single 메서드 구현
  PostgrestTransformBuilder<PostgrestMap> single() {
    return MockPostgrestTransformBuilder();
  }

  // then 메서드 구현
  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future<U>.value(null as U);
  }
}

// PostgrestBuilder 모킹 (Mocktail)
class MockPostgrestBuilder with mocktail.Mock implements PostgrestBuilder {}

// SupabaseQueryBuilder 모킹 (Mocktail)
class MockSupabaseQueryBuilder
    with mocktail.Mock
    implements SupabaseQueryBuilder {}

// PostgrestTransformBuilder 모킹 (Mocktail)
class MockPostgrestTransformBuilder
    with mocktail.Mock
    implements PostgrestTransformBuilder<PostgrestMap> {}

// StorageFileApi 모킹 (Mocktail)
class MockStorageFileApi with mocktail.Mock implements StorageFileApi {
  // update 메서드 구현
  @override
  Future<String> update(String path, File file,
      {FileOptions? fileOptions,
      int? retryAttempts,
      StorageRetryController? retryController}) async {
    return 'https://example.com/new-avatar.jpg';
  }
}

// ImagePicker 및 XFile 모킹 (Mocktail)
class MockImagePicker with mocktail.Mock implements ImagePicker {
  // pickImage 메서드 구현
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return MockXFile();
  }
}

class MockXFile with mocktail.Mock implements XFile {
  @override
  String get path => '/test/path/image.jpg';
}

// ---------- Mockito 기반 모킹 클래스 ----------

// Mockito 기반 SupabaseClient 모킹
class MockitoSupabaseClient extends mockito.Mock implements SupabaseClient {
  final Map<String, dynamic> _mockData = {};
  final Map<String, Function> _mockFunctions = {};

  @override
  GoTrueClient get auth => MockitoSupabaseAuthClient();

  @override
  SupabaseQueryBuilder from(String table) {
    return MockitoSupabaseQueryBuilder(table, _mockData, _mockFunctions);
  }

  void setMockData(String key, dynamic value) {
    _mockData[key] = value;
  }

  void setMockFunction(String key, Function function) {
    _mockFunctions[key] = function;
  }
}

class MockitoSupabaseAuthClient extends mockito.Mock implements GoTrueClient {
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

class MockitoSupabaseQueryBuilder extends mockito.Mock
    implements SupabaseQueryBuilder {
  final String table;
  final Map<String, dynamic> _mockData;
  final Map<String, Function> _mockFunctions;

  MockitoSupabaseQueryBuilder(this.table, this._mockData, this._mockFunctions);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    final key = '$table:$columns';
    if (_mockData.containsKey(key)) {
      return MockitoPostgrestFilterBuilder(
          List<Map<String, dynamic>>.from(_mockData[key]));
    }
    return MockitoPostgrestFilterBuilder([]);
  }

  @override
  PostgrestFilterBuilder<Map<String, dynamic>> single() {
    final key = '$table:single';
    if (_mockData.containsKey(key)) {
      return MockitoPostgrestFilterBuilder(
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
    return MockitoPostgrestFilterBuilder(null);
  }

  @override
  PostgrestFilterBuilder<dynamic> update(Map values) {
    final key = '$table:update';
    if (_mockFunctions.containsKey(key)) {
      _mockFunctions[key]?.call(values);
    }
    return MockitoPostgrestFilterBuilder(null);
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    final key = '$table:delete';
    if (_mockFunctions.containsKey(key)) {
      _mockFunctions[key]?.call();
    }
    return MockitoPostgrestFilterBuilder(null);
  }

  @override
  MockitoSupabaseQueryBuilder eq(String column, dynamic value) {
    return this;
  }

  @override
  MockitoSupabaseQueryBuilder neq(String column, dynamic value) {
    return this;
  }
}

class MockitoPostgrestFilterBuilder<T> extends mockito.Mock
    implements PostgrestFilterBuilder<T> {
  final T _value;

  MockitoPostgrestFilterBuilder(this._value);

  @override
  Future<T> execute() async {
    return _value;
  }
}
