// lib/providers/star_users_info_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarUsersInfoProvider extends ChangeNotifier {
  List<dynamic> _starUsers = [];

  List<dynamic> get starUsers => _starUsers;

  // 즐겨찾기 유저 목록을 로컬 저장소에서 불러오기
  Future<void> loadStarUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('starUsers');
    if (storedData != null) {
      _starUsers = json.decode(storedData);
    } else {
      _starUsers = [];
    }
    notifyListeners();
  }

  // 사용자가 즐겨찾기에 추가되어 있는지 확인
  bool isStarred(Map<String, dynamic> user) {
    return _starUsers.any((element) =>
        element['user_id'].toString() == user['user_id'].toString());
  }

  // 즐겨찾기 토글 (추가/제거)
  Future<void> toggleStarUser(Map<String, dynamic> user) async {
    if (isStarred(user)) {
      await removeStarUser(user['user_id'].toString());
    } else {
      await addStarUser(user);
    }
  }

  // 즐겨찾기에 유저 추가
  Future<void> addStarUser(Map<String, dynamic> user) async {
    // 이미 존재하는지 체크 (예: user_id로 비교)
    if (!_starUsers.any((element) =>
        element['user_id'].toString() == user['user_id'].toString())) {
      _starUsers.add(user);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  // 즐겨찾기에서 유저 제거 (user_id 기준)
  Future<void> removeStarUser(String userId) async {
    _starUsers.removeWhere((user) => user['user_id'].toString() == userId);
    await _saveToPrefs();
    notifyListeners();
  }

  // 내부적으로 SharedPreferences에 저장
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('starUsers', json.encode(_starUsers));
  }

  // 즐겨찾기 목록 전체 삭제
  Future<void> clearStarUsers() async {
    _starUsers.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('starUsers');
    notifyListeners();
  }
}
