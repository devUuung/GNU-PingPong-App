/// 경기 입력 요청을 나타내는 모델 클래스
class MatchRequest {
  final int requestId;
  final int userId;
  final DateTime createdAt;

  MatchRequest({
    required this.requestId,
    required this.userId,
    required this.createdAt,
  });

  /// JSON에서 MatchRequest 객체로 변환하는 팩토리 생성자
  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    return MatchRequest(
      requestId: json['request_id'],
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// MatchRequest 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 사용자 정보가 포함된 경기 입력 요청 클래스
class MatchRequestWithUser {
  final MatchRequest request;
  final Map<String, dynamic> user;

  MatchRequestWithUser({
    required this.request,
    required this.user,
  });

  /// JSON에서 MatchRequestWithUser 객체로 변환하는 팩토리 생성자
  factory MatchRequestWithUser.fromJson(Map<String, dynamic> json) {
    return MatchRequestWithUser(
      request: MatchRequest(
        requestId: json['request_id'],
        userId: json['user']['user_id'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      ),
      user: json['user'],
    );
  }
}
