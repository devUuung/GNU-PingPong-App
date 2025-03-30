import 'package:flutter/material.dart';
import 'home.dart';
import 'signup.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common/loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 학번, 비밀번호 입력 컨트롤러
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    setState(() {
      _isLoading = true;
    });
    await supabase.auth.signOut();

    final session = await supabase.auth.currentSession;

    if (session != null) {
      _goHome();
    }

    _isLoading = false;
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorDialog(context, '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        showErrorDialog(context, '로그인 정보가 틀렸습니다.');
        _isLoading = false;
        return;
      }

      _goHome();
    } catch (e) {
      showErrorDialog(context, '로그인 중 오류 발생: $e');
      _isLoading = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// HomePage로 이동 (pushReplacement)
  void _goHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
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
