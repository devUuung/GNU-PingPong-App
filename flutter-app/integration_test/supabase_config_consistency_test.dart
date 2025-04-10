import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized(); // Integration test 바인딩 초기화

  late SupabaseClient prodClient;
  late SupabaseClient testClient;

  // Deep equality 비교 함수
  final deepEq = const DeepCollectionEquality().equals;
  
  // 리스트 정렬 및 비교를 위한 헬퍼 (JSON 객체 리스트)
  List<Map<String, dynamic>>? sortJsonList(dynamic data, String key) {
    if (data == null || data is! List) return null;
    final list = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e)));
    list.sort((a, b) => (a[key] as Comparable?)?.compareTo(b[key] as Comparable? ?? '') ?? 0);
    return list;
  }

  setUpAll(() async {
    // .env 파일 로드
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('Error loading .env file: $e');
      rethrow;
    }

    final prodSupabaseUrl = dotenv.env['PROD_SUPABASE_URL'];
    final prodSupabaseAnonKey = dotenv.env['PROD_SUPABASE_ANON_KEY'];
    final testSupabaseUrl = dotenv.env['TEST_SUPABASE_URL'];
    final testSupabaseAnonKey = dotenv.env['TEST_SUPABASE_ANON_KEY'];

    if (prodSupabaseUrl == null || prodSupabaseUrl.isEmpty ||
        prodSupabaseAnonKey == null || prodSupabaseAnonKey.isEmpty ||
        testSupabaseUrl == null || testSupabaseUrl.isEmpty ||
        testSupabaseAnonKey == null || testSupabaseAnonKey.isEmpty) {
      throw Exception('Supabase credentials environment variables are not set or empty in .env file.');
    }

    try {
      Supabase.instance;
    } catch (e) {
      await Supabase.initialize(
        url: prodSupabaseUrl,
        anonKey: prodSupabaseAnonKey,
      );
    }
    prodClient = Supabase.instance.client;

    testClient = SupabaseClient(
      testSupabaseUrl,
      testSupabaseAnonKey,
    );
  });

  group('Supabase Configuration Consistency Tests', () {
    testWidgets('Table schemas should be consistent', (WidgetTester tester) async {
      final prodResponse = await prodClient.rpc('get_schema_details');
      final testResponse = await testClient.rpc('get_schema_details');

      expect(prodResponse, isNotNull, reason: 'Failed to fetch prod schema');
      expect(testResponse, isNotNull, reason: 'Failed to fetch test schema');

      final prodSchema = sortJsonList(prodResponse, 'table_name');
      final testSchema = sortJsonList(testResponse, 'table_name');

      // 차이점 상세 출력
      print('\n=== 스키마 비교 결과 ===');
      
      // 테이블 목록 비교
      final prodTables = prodSchema?.map((t) => t['table_name'] as String).toSet() ?? {};
      final testTables = testSchema?.map((t) => t['table_name'] as String).toSet() ?? {};
      
      print('\n프로덕션에만 있는 테이블:');
      print(prodTables.difference(testTables));
      print('\n테스트에만 있는 테이블:');
      print(testTables.difference(prodTables));
      
      // 공통 테이블의 컬럼 비교
      final commonTables = prodTables.intersection(testTables);
      print('\n공통 테이블의 컬럼 차이:');
      
      for (final tableName in commonTables) {
        final prodTable = prodSchema?.firstWhere((t) => t['table_name'] == tableName);
        final testTable = testSchema?.firstWhere((t) => t['table_name'] == tableName);
        
        if (prodTable != null && testTable != null) {
          final prodColumns = (prodTable['columns'] as List?)?.map((c) => c['column_name'] as String).toSet() ?? {};
          final testColumns = (testTable['columns'] as List?)?.map((c) => c['column_name'] as String).toSet() ?? {};
          
          if (prodColumns != testColumns) {
            print('\n테이블: $tableName');
            print('프로덕션에만 있는 컬럼:');
            print(prodColumns.difference(testColumns));
            print('테스트에만 있는 컬럼:');
            print(testColumns.difference(prodColumns));
          }

          // 컬럼 속성 비교
          print('\n테이블: $tableName의 컬럼 속성 비교:');
          for (final columnName in prodColumns.intersection(testColumns)) {
            final prodColumn = (prodTable['columns'] as List?)?.firstWhere((c) => c['column_name'] == columnName);
            final testColumn = (testTable['columns'] as List?)?.firstWhere((c) => c['column_name'] == columnName);
            
            if (prodColumn != null && testColumn != null) {
              print('\n컬럼: $columnName');
              print('프로덕션 속성:');
              print(prodColumn);
              print('테스트 속성:');
              print(testColumn);
            }
          }
        }
      }

      expect(deepEq(prodSchema, testSchema), isTrue, reason: 'Table schemas differ');
    });

    testWidgets('RLS policies should be consistent', (WidgetTester tester) async {
      final prodResponse = await prodClient.rpc('get_rls_policies_details');
      final testResponse = await testClient.rpc('get_rls_policies_details');

      expect(prodResponse, isNotNull, reason: 'Failed to fetch prod RLS policies');
      expect(testResponse, isNotNull, reason: 'Failed to fetch test RLS policies');

      final prodPolicies = sortJsonList(prodResponse, 'policy_name');
      final testPolicies = sortJsonList(testResponse, 'policy_name');

      prodPolicies?.forEach((policy) => (policy['roles'] as List?)?.sort());
      testPolicies?.forEach((policy) => (policy['roles'] as List?)?.sort());

      expect(deepEq(prodPolicies, testPolicies), isTrue, reason: 'RLS policies differ');
    });

    testWidgets('Database functions should be consistent', (WidgetTester tester) async {
      final prodResponse = await prodClient.rpc('get_function_details');
      final testResponse = await testClient.rpc('get_function_details');

      expect(prodResponse, isNotNull, reason: 'Failed to fetch prod functions');
      expect(testResponse, isNotNull, reason: 'Failed to fetch test functions');

      final prodFunctions = sortJsonList(prodResponse, 'function_name');
      final testFunctions = sortJsonList(testResponse, 'function_name');

      prodFunctions?.forEach((func) => (func['argument_types'] as List?)?.sort());
      testFunctions?.forEach((func) => (func['argument_types'] as List?)?.sort());

      expect(deepEq(prodFunctions, testFunctions), isTrue, reason: 'Database functions differ');
    });

    testWidgets('Database triggers should be consistent', (WidgetTester tester) async {
      final prodResponse = await prodClient.rpc('get_trigger_details');
      final testResponse = await testClient.rpc('get_trigger_details');

      expect(prodResponse, isNotNull, reason: 'Failed to fetch prod triggers');
      expect(testResponse, isNotNull, reason: 'Failed to fetch test triggers');

      final prodTriggers = sortJsonList(prodResponse, 'trigger_name');
      final testTriggers = sortJsonList(testResponse, 'trigger_name');

      expect(deepEq(prodTriggers, testTriggers), isTrue, reason: 'Database triggers differ');
    });
  });

  tearDownAll(() async {
    await testClient.dispose();
    // await Supabase.instance.client.dispose(); // 필요한 경우 주석 해제
  });
} 