import 'package:flutter/material.dart';
import '../api_config.dart';
import '../models/index.dart';
import 'api_client.dart';
import 'dart:convert';

/// 게임 관련 API 요청을 처리하는 서비스 클래스
class GameService {
  final ApiClient _apiClient = ApiClient();

  /// 모든 게임 정보를 가져오는 메서드
  Future<List<Game>> getAllGames() async {
    try {
      var response = await _apiClient.get('${ApiConfig.gamesinfo}/all');
      if (response['success'] == true && response['data'] != null) {
        // data가 리스트가 맞는지 확인
        // response['data'] = jsonDecode(response['data']);
        if (response['data'] is List<dynamic>) {
          final List<dynamic> gamesData = response['data'];
          return gamesData.map((game) => Game.fromJson(game)).toList();
        } else {
          debugPrint('getAllGames 오류: 예상치 못한 응답 형식 - data가 리스트가 아님');
          debugPrint('응답: $response');
          return [];
        }
      } else if (response['success'] == true) {
        // GET /games/all 엔드포인트가 다른 형식의 데이터를 반환하는 경우
        debugPrint('getAllGames: 게임 데이터가 없음');
        return [];
      }

      debugPrint('getAllGames 오류: 성공하지 않은 응답');
      debugPrint('응답: $response');
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
        ApiConfig.createGame,
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
