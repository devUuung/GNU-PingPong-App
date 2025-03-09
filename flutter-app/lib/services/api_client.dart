import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

/// API 요청을 처리하는 클라이언트 클래스
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // HTTP 요청 타임아웃 설정
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  /// GET 요청을 보내는 메서드
  Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? headers}) async {
    try {
      final token = await getToken();
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final client = http.Client();
      try {
        final response = await client
            .get(
              Uri.parse(endpoint),
              headers: requestHeaders,
            )
            .timeout(connectionTimeout);

        return _handleResponse(response);
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('GET 요청 중 오류 발생: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// POST 요청을 보내는 메서드
  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      // 로그인 및 회원가입 요청에는 토큰을 포함하지 않음
      final bool isAuthEndpoint =
          endpoint == ApiConfig.login || endpoint == ApiConfig.signUp;

      String? token;
      if (!isAuthEndpoint) {
        token = await getToken();
      }

      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        // 인증 관련 엔드포인트가 아닌 경우에만 토큰 추가
        if (!isAuthEndpoint && token != null) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      debugPrint('POST 요청: $endpoint');
      debugPrint('요청 헤더: $requestHeaders');
      if (body != null) {
        debugPrint('요청 본문: ${jsonEncode(body)}');
      }

      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(endpoint),
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(connectionTimeout);

        debugPrint('응답 상태 코드: ${response.statusCode}');
        debugPrint('응답 헤더: ${response.headers}');
        debugPrint('응답 본문: ${response.body}');

        return _handleResponse(response);
      } on http.ClientException catch (e) {
        debugPrint('HTTP 클라이언트 예외: $e');
        return {
          'success': false,
          'message': '서버 연결 오류: ${e.message}',
          'error_type': 'client_exception'
        };
      } on FormatException catch (e) {
        debugPrint('형식 예외: $e');
        return {
          'success': false,
          'message': '응답 형식 오류: ${e.message}',
          'error_type': 'format_exception'
        };
      } on TimeoutException catch (e) {
        debugPrint('타임아웃 예외: $e');
        return {
          'success': false,
          'message': '요청 시간 초과: 서버 응답이 너무 오래 걸립니다.',
          'error_type': 'timeout_exception'
        };
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('POST 요청 중 오류 발생: $e');
      return {
        'success': false,
        'message': '네트워크 오류: $e',
        'error_type': 'unknown_exception'
      };
    }
  }

  /// PUT 요청을 보내는 메서드
  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final token = await getToken();
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final client = http.Client();
      try {
        final response = await client
            .put(
              Uri.parse(endpoint),
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(connectionTimeout);

        return _handleResponse(response);
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('PUT 요청 중 오류 발생: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// DELETE 요청을 보내는 메서드
  Future<Map<String, dynamic>> delete(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    try {
      final token = await getToken();
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final client = http.Client();
      try {
        final response = await client
            .delete(
              Uri.parse(endpoint),
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(connectionTimeout);

        return _handleResponse(response);
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('DELETE 요청 중 오류 발생: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// 응답을 처리하는 메서드
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'success': true, 'data': response.body};
      }
    } else {
      debugPrint('API 오류: ${response.statusCode}, 응답: ${response.body}');
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': '서버 오류: ${response.statusCode}',
        'data': response.body,
      };
    }
  }

  /// 토큰을 가져오는 메서드
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  /// 토큰을 저장하는 메서드
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  /// 토큰을 삭제하는 메서드
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  /// 토큰 유효성을 검사하는 메서드
  Future<Map<String, dynamic>> validateToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'isValid': false, 'user_id': null};
      }

      final response = await post(
        ApiConfig.validateToken,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true) {
        return {'isValid': true, 'user_id': response['user_id']};
      } else {
        return {'isValid': false, 'user_id': null};
      }
    } catch (e) {
      debugPrint('토큰 검증 중 오류 발생: $e');
      return {'isValid': false, 'user_id': null};
    }
  }
}
