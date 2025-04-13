import 'package:flutter/material.dart';
import 'home.dart';
import 'signup.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common/loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 학번, 비밀번호 입력 컨트롤러
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true; // 자동 로그인 옵션 (기본값: 활성화)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 세션 확인
      final session = supabase.auth.currentSession;
      
      // 세션이 있으면 홈 화면으로 이동
      if (session != null && mounted) {
        _goHome();
        return;
      }
      
      // 세션이 없지만 저장된 로그인 정보가 있으면 자동 로그인 시도
      final prefs = await SharedPreferences.getInstance();
      final savedStudentId = prefs.getString('studentId');
      final savedPassword = prefs.getString('password');
      
      if (savedStudentId != null && savedPassword != null && mounted) {
        // 저장된 정보로 자동 로그인 시도
        final email = '$savedStudentId@gnu.ac.kr';
        
        try {
          final response = await supabase.auth.signInWithPassword(
            email: email,
            password: savedPassword,
          );
          
          if (response.session != null && mounted) {
            _goHome();
            return;
          }
        } catch (e) {
          // 자동 로그인 실패 - 저장된 정보 삭제
          await prefs.remove('studentId');
          await prefs.remove('password');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text.trim();

    if (studentId.isEmpty || password.isEmpty) {
      if (!mounted) return;
      // 입력값이 비어있을 경우, 로딩 상태를 해제한 후 에러 다이얼로그 출력
      setState(() {
        _isLoading = false;
      });
      showErrorDialog(context, '학번과 비밀번호를 입력해주세요.');
      return;
    }

    final email = '$studentId@gnu.ac.kr';

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        if (!mounted) return;
        // 로그인 실패 시 로딩 상태 해제
        setState(() {
          _isLoading = false;
        });
        showErrorDialog(context, '로그인 정보가 틀렸습니다.');
        return;
      }

      // 자동 로그인 설정이 켜져 있으면 로그인 정보 저장
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentId', studentId);
        await prefs.setString('password', password);
      }

      if (mounted) {
        _goHome();
      }
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, '로그인 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  // 학번 입력 필드
                  TextField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: '학번',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // 비밀번호 입력 필드
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  // 자동 로그인 체크박스
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('자동 로그인'),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          builder: (context) => const SignUpPage(),
                        ),
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
