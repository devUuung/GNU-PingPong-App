import 'package:flutter/material.dart';
import '../api_config.dart';
import '../models/index.dart';
import 'api_client.dart';

/// 게임 관련 API 요청을 처리하는 서비스 클래스
class GameService {
  final ApiClient _apiClient = ApiClient();

  /// 모든 게임 정보를 가져오는 메서드
  Future<List<Game>> getAllGames() async {
    try {
      final response = await _apiClient.get('${ApiConfig.gamesinfo}/all');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> gamesData = response['data'];
        return gamesData.map((game) => Game.fromJson(game)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('게임 정보를 가져오는 중 오류 발생: $e');
      return [];
    }
  }

  /// 새로운 게임을 생성하는 메서드
  Future<Game?> createGame(int winnerId, int loserId) async {
    try {
      final gameRequest = GameCreateRequest(
        winnerId: winnerId,
        loserId: loserId,
      );

      final response = await _apiClient.post(
        '${ApiConfig.gamesinfo}/create',
        body: gameRequest.toJson(),
      );

      if (response['success'] == true && response['game'] != null) {
        return Game.fromJson(response['game']);
      }

      return null;
    } catch (e) {
      debugPrint('게임을 생성하는 중 오류 발생: $e');
      return null;
    }
  }

  /// 새로운 게임을 생성하는 메서드 (점수 포함)
  Future<bool> createGameWithScore({
    required int winnerId,
    required int loserId,
    required int plusScore,
    required int minusScore,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.gamesinfo,
        body: {
          'winner_id': winnerId,
          'loser_id': loserId,
          'plus_score': plusScore,
          'minus_score': minusScore,
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('게임을 생성하는 중 오류 발생: $e');
      return false;
    }
  }
}

/// 이전 버전과의 호환성을 위한 클래스
class CreateGameService {
  /// 새로운 경기 기록을 생성하는 함수
  static Future<bool> createGame({
    required int winnerId,
    required int loserId,
    required int plusScore,
    required int minusScore,
  }) async {
    return await GameService().createGameWithScore(
      winnerId: winnerId,
      loserId: loserId,
      plusScore: plusScore,
      minusScore: minusScore,
    );
  }
}
