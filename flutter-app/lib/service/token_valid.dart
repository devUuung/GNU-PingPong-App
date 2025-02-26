import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_app/api_config.dart';

Future<Map<String, dynamic>> validateToken() async {
  final secureStorage = FlutterSecureStorage();
  try {
    final token = await secureStorage.read(key: 'access_token');
    // 토큰이 있고 비어있지 않으면
    if (token != null && token.isNotEmpty) {
      final url = ApiConfig.validateToken;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 토큰이 유효한 경우
      if (response.statusCode == 200) {
        print('토큰 유효: ${response.body}');
        final data = jsonDecode(response.body);
        return {'isValid': true, 'user_id': data['user_id']};
      } else {
        // 토큰이 유효하지 않은 경우 (예: 만료, 위조 등)
        print('토큰 유효하지 않음: ${response.statusCode}');
        return {'isValid': false, 'user_id': null};
      }
    } else {
      // 토큰이 없거나 비어있는 경우
      print('토큰 없음');
      return {'isValid': false, 'user_id': null};
    }
  } catch (e) {
    // 예외 처리
    print('토큰 검증 중 오류 발생: $e');
    return {'isValid': false, 'user_id': null};
  }
}
