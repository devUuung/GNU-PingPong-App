import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

/// 토큰 관련 기능을 제공하는 서비스 클래스
class TokenService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// 토큰 유효성을 검사하는 메서드
  Future<Map<String, dynamic>> validateToken() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      // 토큰이 있고 비어있지 않으면
      if (token != null && token.isNotEmpty) {
        final url = ApiConfig.validateToken;
        final client = http.Client();
        try {
          final response = await client.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(connectionTimeout);

          // 토큰이 유효한 경우
          if (response.statusCode == 200) {
            debugPrint('토큰 유효: ${response.body}');
            final data = jsonDecode(response.body);
            return {'isValid': true, 'user_id': data['user_id']};
          } else {
            // 토큰이 유효하지 않은 경우 (예: 만료, 위조 등)
            debugPrint('토큰 유효하지 않음: ${response.statusCode}');
            return {'isValid': false, 'user_id': null};
          }
        } finally {
          client.close();
        }
      } else {
        // 토큰이 없거나 비어있는 경우
        debugPrint('토큰 없음');
        return {'isValid': false, 'user_id': null};
      }
    } catch (e) {
      // 예외 처리
      debugPrint('토큰 검증 중 오류 발생: $e');
      return {'isValid': false, 'user_id': null};
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
}

/// 이전 버전과의 호환성을 위한 전역 함수
Future<Map<String, dynamic>> validateToken() async {
  return await TokenService().validateToken();
}
