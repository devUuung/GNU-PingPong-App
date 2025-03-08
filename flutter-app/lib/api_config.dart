// lib/api_config.dart
/// API 설정 클래스
class ApiConfig {
  /// 기본 API URL
  // 로컬 테스트용 URL
  // static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // 에뮬레이터에서 테스트할 때 사용하는 URL
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // 실제 서버 URL (배포 시 사용)
  static const String baseUrl = 'http://117.16.153.235:8000/api/v1';

  /// 회원가입 API URL
  static const String signUp = '$baseUrl/users/signup';

  /// 로그인 API URL
  static const String login = '$baseUrl/users/login';

  /// 사용자 정보 API URL
  static const String userinfo = '$baseUrl/users';

  /// 모든 사용자 정보 API URL
  static const String allUsersInfo = '$baseUrl/users/all';

  /// 토큰 검증 API URL
  static const String validateToken = '$baseUrl/users/validate-token';

  /// 게임 정보 API URL
  static const String gamesinfo = '$baseUrl/games';

  /// 모집 공고 생성 API URL
  static const String recruitPost = '$baseUrl/recruit/post';

  /// 모집 공고 목록 조회 API URL
  static const String recruitPosts = '$baseUrl/recruit/posts';
}
