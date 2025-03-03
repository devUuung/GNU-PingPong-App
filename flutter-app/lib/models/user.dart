/// 사용자 정보를 나타내는 모델 클래스
class User {
  final int userId;
  final String username;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? statusMessage;
  final int studentId;
  final double score;
  final int totalPrize;
  final int gameCount;
  final int winCount;
  final int loseCount;
  final double initialScore;
  final int point;
  final bool isAdmin;
  final String? deviceId;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.username,
    required this.phoneNumber,
    this.profileImageUrl,
    this.statusMessage = "안녕하세요!",
    required this.studentId,
    this.score = 0,
    this.totalPrize = 0,
    this.gameCount = 0,
    this.winCount = 0,
    this.loseCount = 0,
    this.initialScore = 0,
    this.point = 0,
    this.isAdmin = false,
    this.deviceId,
    required this.createdAt,
  });

  /// JSON에서 User 객체로 변환하는 팩토리 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      statusMessage: json['status_message'] ?? "안녕하세요!",
      studentId: json['student_id'],
      score: json['score']?.toDouble() ?? 0.0,
      totalPrize: json['total_prize'] ?? 0,
      gameCount: json['game_count'] ?? 0,
      winCount: json['win_count'] ?? 0,
      loseCount: json['lose_count'] ?? 0,
      initialScore: json['initial_score']?.toDouble() ?? 0.0,
      point: json['point'] ?? 0,
      isAdmin: json['is_admin'] ?? false,
      deviceId: json['device_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// User 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'status_message': statusMessage,
      'student_id': studentId,
      'score': score,
      'total_prize': totalPrize,
      'game_count': gameCount,
      'win_count': winCount,
      'lose_count': loseCount,
      'initial_score': initialScore,
      'point': point,
      'is_admin': isAdmin,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 사용자 정보를 업데이트하는 메서드
  User copyWith({
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    String? statusMessage,
    double? score,
    int? totalPrize,
    int? gameCount,
    int? winCount,
    int? loseCount,
    int? point,
    String? deviceId,
  }) {
    return User(
      userId: this.userId,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      studentId: this.studentId,
      score: score ?? this.score,
      totalPrize: totalPrize ?? this.totalPrize,
      gameCount: gameCount ?? this.gameCount,
      winCount: winCount ?? this.winCount,
      loseCount: loseCount ?? this.loseCount,
      initialScore: this.initialScore,
      point: point ?? this.point,
      isAdmin: this.isAdmin,
      deviceId: deviceId ?? this.deviceId,
      createdAt: this.createdAt,
    );
  }
}
