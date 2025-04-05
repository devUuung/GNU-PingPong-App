import 'package:flutter/material.dart';
import '../utils/dialog_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

final supabase = Supabase.instance.client;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      final studentId = _studentIdController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();
      final phone = _phoneController.text.trim();

      if (password != confirmPassword) {
        showErrorDialog(context, '비밀번호가 일치하지 않습니다.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 학번을 이메일 형식으로 변환
        final email = '$studentId@gnu.ac.kr';

        final AuthResponse response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'student_id': studentId,
            'phone': phone,
          },
        );

        if (response.user == null) {
          if (!mounted) return;
          showErrorDialog(context, '회원가입에 실패했습니다.');
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        if (!mounted) return;
        showErrorDialog(context, '회원가입 중 오류가 발생했습니다: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFFFEF7FF),
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('학번', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '학번을 입력하세요.',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '학번을 입력해주세요.';
                  }
                  if (value.length != 8) {
                    return '학번은 8자리여야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '비밀번호를 입력하세요.',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('비밀번호 확인',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '비밀번호를 다시 입력하세요.',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('전화번호', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '전화번호를 입력하세요.',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '전화번호를 입력해주세요.';
                  }
                  if (!RegExp(r'^01[0-9]-?[0-9]{4}-?[0-9]{4}$')
                      .hasMatch(value)) {
                    return '올바른 전화번호 형식이 아닙니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          backgroundColor:
                              const Color.fromRGBO(101, 85, 143, 1),
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
