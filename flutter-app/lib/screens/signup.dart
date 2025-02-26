import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../api_config.dart'; // api_config.dart를 import 합니다.
import '../dialog.dart'; // 다이얼로그 사용을 위한 import

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _statusMessageController = TextEditingController(text: '안녕하세요!');

  // 기본 프로필 이미지 URL - 수정된 경로
  final String _defaultProfileImageUrl =
      'http://0.0.0.0:8000/static/default_profile.png';

  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    final studentId = _studentIdController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final statusMessage = _statusMessageController.text.trim();

    if (studentId.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('모든 필드를 입력해주세요.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // api_config.dart에서 관리하는 엔드포인트 사용
    final url = ApiConfig.signUp;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'student_id': studentId,
          'name': name,
          'phone': phone,
          'password': password,
          'status_message': statusMessage,
        }),
      );

      print(response.body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _showMessage('회원가입이 완료되었습니다!');
          Navigator.pop(context);
        } else {
          final errMsg = responseData['message'] ?? '알 수 없는 오류가 발생했습니다.';
          _showMessage(errMsg);
        }
      } else {
        _showMessage('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('회원가입 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 학번
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: '학번',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              // 이름
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                ),
              ),
              // 전화번호
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                ),
                keyboardType: TextInputType.phone,
              ),
              // 상태 메시지
              TextField(
                controller: _statusMessageController,
                decoration: const InputDecoration(
                  labelText: '상태 메시지',
                  hintText: '한 줄 소개를 입력하세요',
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
              // 비밀번호 확인
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('회원가입'),
                ),
              ),
              const SizedBox(height: 10),
              // 로그인 화면으로 돌아가기
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('이미 계정이 있으신가요? 로그인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
