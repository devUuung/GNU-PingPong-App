// lib/providers/users_info_provider.dart
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../api_config.dart';

class UsersInfoProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  User? _currentUser;
  List<User>? _allUsers;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  User? get userInfo => _currentUser;
  List<User>? get allUsers => _allUsers;
  List<User>? get users => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 프로필 이미지 URL이 올바른지 확인하고 수정하는 헬퍼 메서드
  User _ensureValidProfileImageUrl(User user) {
    if (user.profileImageUrl == null || user.profileImageUrl!.isEmpty) {
      return user;
    }

    // URL이 이미 완전한 형태(http로 시작)인지 확인
    if (user.profileImageUrl!.startsWith('http')) {
      return user;
    }

    // 상대 경로인 경우 서버 기본 주소를 추가하여 완전한 URL로 만듦
    String serverBase = ApiConfig.baseUrl.split('/api/v1').first;
    String fullUrl = '$serverBase/${user.profileImageUrl!}';
    debugPrint('이미지 URL 생성: $fullUrl');

    return user.copyWith(profileImageUrl: fullUrl);
  }

  /// 현재 사용자 정보를 가져오는 메서드
  Future<User?> fetchCurrentUser() async {
    _isLoading = true;
    _error = null;

    try {
      _currentUser = await _userService.getCurrentUser();

      // 프로필 이미지 URL 수정
      if (_currentUser != null) {
        _currentUser = _ensureValidProfileImageUrl(_currentUser!);
      }

      return _currentUser;
    } catch (e) {
      _error = '사용자 정보를 가져오는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 모든 사용자 정보를 가져오는 메서드
  Future<List<User>?> fetchAllUsers() async {
    _isLoading = true;
    _error = null;

    try {
      // 먼저 현재 사용자 정보를 확인
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();

        // 프로필 이미지 URL 수정
        if (_currentUser != null) {
          _currentUser = _ensureValidProfileImageUrl(_currentUser!);
        }
      }

      // 모든 사용자가 유저 목록을 볼 수 있도록 관리자 권한 체크 제거
      _allUsers = await _userService.getAllUsers();

      // 각 사용자의 프로필 이미지 URL 확인 및 수정
      if (_allUsers != null) {
        _allUsers = _allUsers!
            .map((user) => _ensureValidProfileImageUrl(user))
            .toList();
      }

      return _allUsers;
    } catch (e) {
      _error = '사용자 정보를 가져오는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 정보를 업데이트하는 메서드
  Future<User?> updateUser(
      {String? username, String? phoneNumber, String? statusMessage}) async {
    _isLoading = true;
    _error = null;

    try {
      final updatedUser = await _userService.updateUser(
        username: username,
        phoneNumber: phoneNumber,
        statusMessage: statusMessage,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
      }
      return _currentUser;
    } catch (e) {
      _error = '사용자 정보를 업데이트하는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그아웃 메서드
  Future<void> logout() async {
    _isLoading = true;

    try {
      await _userService.logout();
      _currentUser = null;
      _allUsers = null;
    } catch (e) {
      _error = '로그아웃 중 오류가 발생했습니다: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 이전 버전과의 호환성을 위한 메서드 (fetchCurrentUser 호출)
  Future<User?> fetchUserInfo([BuildContext? context]) async {
    return await fetchCurrentUser();
  }

  /// 이전 버전과의 호환성을 위한 메서드 (fetchAllUsers 호출)
  Future<List<User>?> fetchUsersInfo([BuildContext? context]) async {
    return await fetchAllUsers();
  }

  Future<void> initializeData() async {
    await fetchCurrentUser();
    await fetchAllUsers();
  }
}
