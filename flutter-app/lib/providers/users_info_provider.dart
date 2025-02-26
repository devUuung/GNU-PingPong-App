// lib/providers/users_info_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/api_config.dart';
import 'package:flutter_app/dialog.dart';
import 'package:flutter_app/service/token_valid.dart'; // validateToken 함수 사용을 위해 import

class UsersInfoProvider extends ChangeNotifier {
  List<dynamic>? _users;
  Map<String, dynamic>? _userInfo; // 단일 사용자 정보를 저장하는 변수
  bool _isLoading = false;

  List<dynamic>? get users => _users;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  Future<void> fetchUserInfo([BuildContext? context]) async {
    // 로딩 상태 시작
    _isLoading = true;
    // 빌드 중이 아닐 때만 notifyListeners 호출
    if (context == null) {
      notifyListeners();
    }

    try {
      final tokenData = await validateToken();
      if (tokenData['user_id'] != null) {
        final int myUserId = tokenData['user_id'];
        final url = ApiConfig.userinfo + '/$myUserId';
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            _userInfo = data['user'];
            print("사용자 정보 로드 완료: $_userInfo");
          } else {
            print('사용자 정보 가져오기 실패: ${data['message']}');
          }
        } else {
          print('API 오류: ${response.statusCode}');
        }
      } else {
        print('유효한 사용자 ID를 찾을 수 없음');
      }
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
    } finally {
      // 로딩 상태 종료
      _isLoading = false;
      // 빌드 중이 아닐 때만 notifyListeners 호출
      if (context == null) {
        notifyListeners();
      } else {
        // 빌드 과정 중이라면 다음 프레임에서 알림
        Future.microtask(() => notifyListeners());
      }
    }
  }

  Future<void> fetchUsersInfo(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // API 호출하여 최신 데이터 가져오기
      final url = ApiConfig.allUsersInfo; // 모든 유저 정보를 반환하는 API 엔드포인트
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _users = data['users'];
          print("API 호출 후 저장된 유저 정보: $_users");
        } else {
          print('유저 정보 가져오기 실패');
        }
      } else {
        print('API 오류: ${response.statusCode}');
      }

      // validateToken 함수를 호출하여 현재 사용자 user_id 가져오기
      final tokenData = await validateToken();
      if (tokenData['user_id'] != null) {
        final int myUserId = tokenData['user_id'];
        // _users를 List<Map<String, dynamic>>로 캐스팅 후, 현재 user_id와 일치하는 사용자 찾기
        final List<Map<String, dynamic>> usersList =
            _users?.cast<Map<String, dynamic>>() ?? [];

        try {
          _userInfo =
              usersList.firstWhere((user) => user['user_id'] == myUserId);
        } catch (e) {
          // 일치하는 사용자가 없으면 _userInfo는 null로 남김
          _userInfo = null;
          print("현재 사용자를 찾지 못함: $e");
        }
      }
    } catch (e) {
      print('유저 정보를 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
