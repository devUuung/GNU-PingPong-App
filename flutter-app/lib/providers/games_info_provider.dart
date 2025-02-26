// lib/providers/games_info_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/api_config.dart';
import 'package:flutter_app/dialog.dart';

class GamesInfoProvider extends ChangeNotifier {
  List<dynamic>? _games;
  bool _isLoading = false;

  List<dynamic>? get games => _games;
  bool get isLoading => _isLoading;

  Future<void> fetchGamesInfo(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // API 호출하여 최신 데이터 가져오기
      final url = ApiConfig.gamesinfo; // 경기 기록 API URL (ApiConfig에 정의)
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _games = data['games'];
          print("API 호출 후 저장된 경기 기록: $_games");
        } else {
          print('경기 기록 가져오기 실패');
        }
      } else {
        print('API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('경기 기록 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 경기 기록 삭제: id에 해당하는 경기 기록을 리스트에서 제거
  void removeGameRecord(String id) {
    if (_games != null) {
      _games = _games!.where((game) => game['id'] != id).toList();
      notifyListeners();
    }
  }
}
