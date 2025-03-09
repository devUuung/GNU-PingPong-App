import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/index.dart';
import 'api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 사용자 관련 API 요청을 처리하는 서비스 클래스
class UserService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 로그인 요청을 처리하는 메서드
  Future<Map<String, dynamic>> login(String studentId, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        body: {
          'student_id': studentId,
          'password': password,
        },
      );

      if (response['success'] == true) {
        final token = response['access_token'];
        if (token != null) {
          await _apiClient.saveToken(token);
        }
      }

      return response;
    } catch (e) {
      debugPrint('로그인 중 오류 발생: $e');
      return {'success': false, 'message': '로그인 중 오류 발생: $e'};
    }
  }

  /// 회원가입 요청을 처리하는 메서드
  Future<Map<String, dynamic>> signup(
      String username,
      String phoneNumber,
      String password,
      String studentId,
      String deviceId,
      String department) async {
    try {
      // 디버그 로그 추가
      debugPrint('회원가입 요청 데이터:');
      debugPrint('username: $username');
      debugPrint('phone_number: $phoneNumber');
      debugPrint('password: $password');
      debugPrint('student_id: $studentId');
      debugPrint('department: $department');

      final response = await _apiClient.post(
        ApiConfig.signUp,
        body: {
          'username': username,
          'phone_number': phoneNumber,
          'password': password,
          'student_id': studentId,
          'device_id': deviceId,
          'department': department,
        },
      );

      return response;
    } catch (e) {
      debugPrint('회원가입 중 오류 발생: $e');
      return {'success': false, 'message': '회원가입 중 오류 발생: $e'};
    }
  }

  /// 현재 사용자 정보를 가져오는 메서드
  Future<User?> getCurrentUser() async {
    try {
      final tokenData = await _apiClient.validateToken();
      if (tokenData['isValid'] != true || tokenData['user_id'] == null) {
        return null;
      }

      final userId = tokenData['user_id'];
      final response = await _apiClient.get('${ApiConfig.userinfo}/$userId');

      if (response['success'] == true && response['user'] != null) {
        return User.fromJson(response['user']);
      }

      return null;
    } catch (e) {
      debugPrint('사용자 정보를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  /// 모든 사용자 정보를 가져오는 메서드
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _apiClient.get(ApiConfig.allUsersInfo);
      debugPrint('사용자 목록 응답: ${response.toString()}');

      if (response['success'] == true && response['users'] != null) {
        final List<dynamic> usersJson = response['users'];
        return usersJson
            .map((userJson) {
              try {
                return User.fromJson(userJson);
              } catch (e) {
                debugPrint('사용자 객체 파싱 오류: $e');
                debugPrint('문제가 있는 JSON: $userJson');
                // 오류가 발생한 항목은 건너뛰고 계속 진행
                return null;
              }
            })
            .where((user) => user != null)
            .cast<User>()
            .toList();
      } else {
        throw Exception(
            '사용자 정보를 불러오는데 실패했습니다: ${response['message'] ?? "알 수 없는 오류"}');
      }
    } catch (e) {
      debugPrint('getAllUsers 오류: $e');
      rethrow;
    }
  }

  /// 특정 사용자 정보를 가져오는 메서드
  Future<User?> getUserById(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.userinfo}/$userId');

      if (response['success'] == true && response['user'] != null) {
        return User.fromJson(response['user']);
      }

      return null;
    } catch (e) {
      debugPrint('사용자 정보를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  /// 사용자 정보를 업데이트하는 메서드
  Future<User?> updateUser(
      {String? username, String? phoneNumber, String? statusMessage}) async {
    try {
      final tokenData = await _apiClient.validateToken();
      if (tokenData['isValid'] != true || tokenData['user_id'] == null) {
        return null;
      }

      final Map<String, dynamic> updateData = {};
      if (username != null) updateData['username'] = username;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (statusMessage != null) updateData['status_message'] = statusMessage;

      final response = await _apiClient.put(
        '${ApiConfig.userinfo}/me',
        body: updateData,
      );

      if (response['success'] == true && response['user'] != null) {
        return User.fromJson(response['user']);
      }

      return null;
    } catch (e) {
      debugPrint('사용자 정보를 업데이트하는 중 오류 발생: $e');
      return null;
    }
  }

  /// 프로필 이미지를 업로드하는 메서드
  Future<User?> uploadProfileImage(File imageFile) async {
    try {
      final tokenData = await _apiClient.validateToken();
      if (tokenData['isValid'] != true || tokenData['user_id'] == null) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.userinfo}/me/profile-image'),
      );

      final token = await _apiClient.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }

      return null;
    } catch (e) {
      debugPrint('프로필 이미지를 업로드하는 중 오류 발생: $e');
      return null;
    }
  }

  /// 비밀번호를 변경하는 메서드
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final tokenData = await _apiClient.validateToken();
      if (tokenData['isValid'] != true || tokenData['user_id'] == null) {
        return false;
      }

      final response = await _apiClient.put(
        '${ApiConfig.userinfo}/me/password',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('비밀번호를 변경하는 중 오류 발생: $e');
      return false;
    }
  }

  /// 로그아웃 메서드
  Future<void> logout() async {
    await _apiClient.deleteToken();
  }

  /// 경기 입력 요청을 생성하는 메서드
  Future<MatchRequest> createMatchRequest() async {
    try {
      final response = await _apiClient.post(ApiConfig.createMatchRequest);
      if (response['success'] == true) {
        return MatchRequest(
          requestId: response['request_id'],
          userId: response['user_id'],
          createdAt: DateTime.parse(response['created_at']),
          isActive: response['is_active'],
        );
      } else {
        throw Exception('경기 입력 요청 생성에 실패했습니다: ${response['message']}');
      }
    } catch (e) {
      debugPrint('createMatchRequest 오류: $e');
      rethrow;
    }
  }

  /// 내 경기 입력 요청 상태를 확인하는 메서드
  Future<MatchRequest?> getMyMatchRequest() async {
    try {
      final response = await _apiClient.get(ApiConfig.getMyMatchRequest);
      if (response['success'] == true) {
        return MatchRequest(
          requestId: response['request_id'],
          userId: response['user_id'],
          createdAt: DateTime.parse(response['created_at']),
          isActive: response['is_active'],
        );
      } else {
        return null; // 요청이 없는 경우
      }
    } catch (e) {
      debugPrint('getMyMatchRequest 오류: $e');
      return null;
    }
  }

  /// 모든 활성화된 경기 입력 요청을 가져오는 메서드
  Future<List<MatchRequestWithUser>> getAllMatchRequests() async {
    try {
      final response = await _apiClient.get(ApiConfig.getAllMatchRequests);
      if (response['success'] == true && response['match_requests'] != null) {
        return (response['match_requests'] as List)
            .map((requestJson) => MatchRequestWithUser.fromJson(requestJson))
            .toList();
      } else {
        throw Exception('경기 입력 요청 목록을 불러오는데 실패했습니다: ${response['message']}');
      }
    } catch (e) {
      debugPrint('getAllMatchRequests 오류: $e');
      rethrow;
    }
  }

  /// 내 경기 입력 요청을 취소하는 메서드
  Future<bool> cancelMatchRequest() async {
    try {
      final response = await _apiClient.delete(ApiConfig.cancelMatchRequest);
      return response['success'] == true;
    } catch (e) {
      debugPrint('cancelMatchRequest 오류: $e');
      return false;
    }
  }
}
