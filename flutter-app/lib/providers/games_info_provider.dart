// lib/providers/games_info_provider.dart
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class GamesInfoProvider extends ChangeNotifier {
  final GameService _gameService = GameService();

  List<Game>? _games;
  bool _isLoading = false;
  String? _error;

  List<Game>? get games => _games;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 모든 게임 정보를 가져오는 메서드
  Future<List<Game>?> fetchAllGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _games = await _gameService.getAllGames();
      return _games;
    } catch (e) {
      _error = '게임 정보를 가져오는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로운 게임을 생성하는 메서드
  Future<Game?> createGame(int winnerId, int loserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGame = await _gameService.createGame(winnerId, loserId);

      if (newGame != null) {
        // 게임 목록이 이미 로드되어 있으면 새 게임을 추가
        if (_games != null) {
          _games = [newGame, ..._games!];
        } else {
          _games = [newGame];
        }
      }

      return newGame;
    } catch (e) {
      _error = '게임을 생성하는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 게임 기록 삭제: gameId에 해당하는 게임 기록을 리스트에서 제거
  void removeGameRecord(int gameId) {
    if (_games != null) {
      _games = _games!.where((game) => game.gameId != gameId).toList();
      notifyListeners();
    }
  }

  /// 이전 버전과의 호환성을 위한 메서드 (fetchAllGames 호출)
  Future<List<Game>?> fetchGamesInfo([BuildContext? context]) async {
    return await fetchAllGames();
  }
}
