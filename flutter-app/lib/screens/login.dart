import 'dart:io'; // 기기 플랫폼 판별용
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'signup.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import 'package:flutter_app/dialog.dart';
import 'package:flutter_app/service/token_valid.dart';

// FlutterSecureStorage 인스턴스 생성 (보통 전역에서 한 번 생성)
final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 디버그 모드 on/off (예: true이면 디버깅 모드)
  final bool _isDebugMode = false;

  // 학번, 비밀번호 입력 컨트롤러
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      final result = await validateToken();
      debugPrint('validateToken 결과: $result'); // 결과 로그 출력
      if (result['isValid'] == true) {
        print('자동 로그인 성공');
        _goHome();
      }
    } catch (e) {
      debugPrint('자동 로그인 체크 에러: $e');
    }
  }

  Future<void> _login() async {
    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      showErrorDialog(context, '학번과 비밀번호를 입력해주세요.');
      return;
    }

    final url = ApiConfig.login;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final jwtToken = data['access_token'];
          if (jwtToken == null) {
            showErrorDialog(context, 'JWT 토큰이 없습니다.');
            return;
          }
          // 기존 토큰 삭제
          await secureStorage.delete(key: 'access_token');
          // 새 토큰 저장
          await secureStorage.write(key: 'access_token', value: jwtToken);
          _goHome();
        } else {
          showErrorDialog(context, '로그인 정보가 틀렸습니다.');
        }
      } else {
        showErrorDialog(context, '서버 통신 에러: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog(context, '로그인 중 오류 발생: $e');
    }
  }

  /// HomePage로 이동 (pushReplacement)
  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 학번
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '학번',
              ),
            ),
            // 비밀번호
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // 로그인 버튼
            ElevatedButton(
              onPressed: _login, // API 요청 또는 디버그 모드 시 즉시 로그인
              child: const Text('로그인'),
            ),
            const SizedBox(height: 10),
            // 회원가입 버튼
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text('회원가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
