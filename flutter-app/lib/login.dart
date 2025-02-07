import 'dart:io'; // 기기 플랫폼 판별용
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// 기기 정보 가져오기
import 'package:device_info_plus/device_info_plus.dart';
// 로컬에 자동로그인 여부나 기기정보 저장 시
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 디버그 모드 on/off (예: true이면 디버깅 모드)
  final bool _isDebugMode = true;

  // 학번, 비밀번호 입력 컨트롤러
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  // 기기 식별자(간단 예시)
  String? _deviceIdentifier;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo(); // 기기 정보 조회
    _checkAutoLogin(); // 자동 로그인 시도
  }

  /// 1) 기기 정보 읽기
  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    // 안드로이드 / iOS 등을 dart:io의 Platform 으로 구분
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // 최신 device_info_plus에는 androidId가 없으므로, id 사용
      _deviceIdentifier = androidInfo.id; // 빌드 ID 등
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceIdentifier = iosInfo.identifierForVendor; // iOS 기기 고유 ID
    } else {
      // 웹, Windows, macOS 등 다른 플랫폼은 별도 처리
      _deviceIdentifier = 'unknown_device';
    }
  }

  /// 2) 자동 로그인 여부 체크
  Future<void> _checkAutoLogin() async {
    // 디버그 모드라면, 자동 로그인 체크 과정 자체를 생략할 수도 있음
    if (_isDebugMode) {
      // 디버그 모드에서는 자동 로그인 여부 상관없이 그냥 무시
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedDeviceId = prefs.getString('deviceId');
    final savedStudentId = prefs.getString('studentId');

    // 만약 로컬에 저장된 'deviceId'와 'studentId'가 존재한다면,
    // "이미 동일 기기=자동로그인" 로직으로 간단 처리 가능
    if (savedDeviceId != null && savedStudentId != null) {
      if (savedDeviceId == _deviceIdentifier) {
        // 이미 내 기기로 로그인했던 기록 있음 => 자동 로그인
        _goHome(); // HomePage로 이동
      }
    }
  }

  /// 3) 로그인 버튼 클릭 시 API 요청
  Future<void> _login() async {
    // 디버그 모드에서는 바로 접속 성공 처리
    if (_isDebugMode) {
      // 학번, 비밀번호 입력 여부 무시하고 바로 홈으로 이동
      _goHome();
      return;
    }

    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      _showErrorDialog('학번과 비밀번호를 입력해주세요.');
      return;
    }

    // 실제 로그인 API 엔드포인트 (예시 URL)
    const url = 'https://example.com/api/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'student_id': studentId,
          'password': password,
          'device_id': _deviceIdentifier ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 예: { "success": true, "message": "...", "deviceMatch": true/false }
        if (data['success'] == true) {
          // 서버측에서 "기기정보 일치" 여부를 준다면
          bool deviceMatch = data['deviceMatch'] ?? false;

          // 로컬 저장
          final prefs = await SharedPreferences.getInstance();
          if (deviceMatch) {
            await prefs.setString('deviceId', _deviceIdentifier ?? '');
            await prefs.setString('studentId', studentId);
          }

          // 로그인 성공 → 홈화면 이동
          _goHome();
        } else {
          _showErrorDialog('로그인 정보가 틀렸습니다.');
        }
      } else {
        // HTTP 오류
        _showErrorDialog('서버 통신 에러: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 발생
      _showErrorDialog('로그인 중 오류 발생: $e');
    }
  }

  /// HomePage로 이동 (pushReplacement)
  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  /// 다이얼로그로 에러 메시지 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        );
      },
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
