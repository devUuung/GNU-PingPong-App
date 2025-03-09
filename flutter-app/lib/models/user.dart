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
  final int customPoint;
  final int rank;
  final String department;
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
    this.customPoint = 0,
    this.rank = 0,
    this.department = "",
    required this.createdAt,
  });

  /// JSON에서 User 객체로 변환하는 팩토리 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        userId: json['user_id'] ?? 0,
        username: json['username'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        profileImageUrl: json['profile_image_url'],
        statusMessage: json['status_message'] ?? "안녕하세요!",
        studentId: json['student_id'] ?? 0,
        score: _parseDouble(json['score']),
        totalPrize: json['total_prize'] ?? 0,
        gameCount: json['game_count'] ?? 0,
        winCount: json['win_count'] ?? 0,
        loseCount: json['lose_count'] ?? 0,
        initialScore: _parseDouble(json['initial_score']),
        point: json['point'] ?? 0,
        isAdmin: json['is_admin'] ?? false,
        deviceId: json['device_id'],
        customPoint: json['custom_point'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        rank: json['rank'] ?? 0,
        department: json['department'] ?? "",
      );
    } catch (e) {
      print('User.fromJson 오류: $e');
      print('문제가 있는 JSON: $json');
      rethrow;
    }
  }

  /// double 값을 안전하게 파싱하는 헬퍼 메서드
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
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
      'custom_point': customPoint,
      'rank': rank,
      'department': department,
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
    int? customPoint,
    int? rank,
    String? department,
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
      customPoint: customPoint ?? this.customPoint,
      createdAt: this.createdAt,
      rank: rank ?? this.rank,
      department: department ?? this.department,
    );
  }
}
