/// 게임 정보를 나타내는 모델 클래스
class Game {
  final int gameId;
  final int winnerId;
  final int loserId;
  final String winnerName;
  final String loserName;
  final int plusScore;
  final int minusScore;
  final DateTime createdAt;

  Game({
    required this.gameId,
    required this.winnerId,
    required this.loserId,
    required this.winnerName,
    required this.loserName,
    required this.plusScore,
    required this.minusScore,
    required this.createdAt,
  });

  /// JSON에서 Game 객체로 변환하는 팩토리 생성자
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['game_id'],
      winnerId: json['winner_id'],
      loserId: json['loser_id'],
      winnerName: json['winner_name'],
      loserName: json['loser_name'],
      plusScore: json['plus_score'] ?? 0,
      minusScore: json['minus_score'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Game 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'winner_id': winnerId,
      'loser_id': loserId,
      'winner_name': winnerName,
      'loser_name': loserName,
      'plus_score': plusScore,
      'minus_score': minusScore,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 게임 생성 요청을 위한 모델 클래스
class GameCreateRequest {
  final int winnerId;
  final int loserId;

  GameCreateRequest({
    required this.winnerId,
    required this.loserId,
  });

  /// GameCreateRequest 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'winner_id': winnerId,
      'loser_id': loserId,
    };
  }
}
