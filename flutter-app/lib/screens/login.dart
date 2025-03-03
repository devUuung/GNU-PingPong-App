import 'dart:io'; // 기기 플랫폼 판별용
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'signup.dart';
import '../providers/users_info_provider.dart';
import '../services/user_service.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common/loading_indicator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 학번, 비밀번호 입력 컨트롤러
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        debugPrint('자동 로그인 성공');
        _goHome();
      }
    } catch (e) {
      debugPrint('자동 로그인 체크 에러: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      showErrorDialog(context, '학번과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _userService.login(studentId, password);

      if (response['success'] == true) {
        // 사용자 정보 가져오기
        final usersProvider =
            Provider.of<UsersInfoProvider>(context, listen: false);
        await usersProvider.fetchCurrentUser();
        _goHome();
      } else {
        showErrorDialog(context, response['message'] ?? '로그인 정보가 틀렸습니다.');
      }
    } catch (e) {
      showErrorDialog(context, '로그인 중 오류 발생: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      body: _isLoading
          ? const LoadingIndicator(message: '로그인 중...')
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 학번
                  TextField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: '학번',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // 비밀번호
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('로그인', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 회원가입 버튼
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
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
