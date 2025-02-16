// lib/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://0.0.0.0:8000/api';
  static const String signUp = '$baseUrl/signup';
  static const String login = '$baseUrl/login';
  static const String userinfo = '$baseUrl/userinfo';
  static const String validateToken = '$baseUrl/validateToken';
}
