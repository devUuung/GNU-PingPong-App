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
  Future<Map<String, dynamic>> signup(String username, String phoneNumber,
      String password, String studentId, String deviceId) async {
    try {
      // 디버그 로그 추가
      debugPrint('회원가입 요청 데이터:');
      debugPrint('username: $username');
      debugPrint('phone_number: $phoneNumber');
      debugPrint('password: $password');
      debugPrint('student_id: $studentId');

      final response = await _apiClient.post(
        ApiConfig.signUp,
        body: {
          'username': username,
          'phone_number': phoneNumber,
          'password': password,
          'student_id': studentId,
          'device_id': deviceId,
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

      if (response['success'] == true && response['users'] != null) {
        final List<dynamic> usersData = response['users'];
        return usersData.map((user) => User.fromJson(user)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('모든 사용자 정보를 가져오는 중 오류 발생: $e');
      return [];
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
}
