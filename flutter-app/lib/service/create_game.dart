import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/api_config.dart';

/// 경기 생성 관련 API 호출을 담당하는 서비스 클래스
class CreateGameService {
  /// 새로운 경기 기록을 생성하는 함수
  /// - [participants]: 경기 참가자 리스트 (예: ['김학생', '박학생'])
  /// - [date]: 경기 날짜 (DateTime 객체)
  /// - [location]: 경기 장소 (예: '체육관 A')
  /// - [winner]: 승리한 참가자 이름
  ///
  /// 반환값은 생성 성공 여부 (true: 성공, false: 실패)
  static Future<bool> createGame({
    required int winnerId,
    required int loserId,
    required int plusScore,
    required int minusScore,
  }) async {
    final url = Uri.parse(ApiConfig.gamesinfo);
    final Map<String, dynamic> requestBody = {
      'winner_id': winnerId,
      'loser_id': loserId,
      'plus_score': plusScore,
      'minus_score': minusScore,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공적으로 생성됨
        print('경기 생성 성공: ${response.body}');
        return true;
      } else {
        // 생성 실패 시 로그 출력
        print(
          '경기 생성 실패 - 상태 코드: ${response.statusCode}, 응답: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      // 네트워크 오류 혹은 예외 발생 시
      print('경기 생성 중 오류 발생: $e');
      return false;
    }
  }
}
