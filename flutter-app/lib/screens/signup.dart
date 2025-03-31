import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common/loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home.dart';
import 'dart:io';

final supabase = Supabase.instance.client;

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthResponse res = await supabase.auth.signUp(
      email: '${_studentIdController.text.trim()}@gnu.ac.kr',
      password: _passwordController.text.trim(),
      data: {
        'username': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'phone': _phoneController.text.trim(),
      },
    );

    // Load the default avatar from assets and write to a temporary file
    final byteData = await rootBundle.load('lib/assets/default_avatar.png');
    final tempDir = await getTemporaryDirectory();
    final avatarPath = '${tempDir.path}/default_avatar.png';
    final avatarFile = File(avatarPath);
    await avatarFile.writeAsBytes(byteData.buffer.asUint8List());

    await supabase.storage.from('avatars').upload(
          'public/${res.user!.id}.png',
          avatarFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    try {
      await supabase.from('userinfo').update({
        'avatar_url': 'public/${res.user!.id}.png',
      }).eq('id', res.user!.id);
    } catch (e) {
      print('Update error: $e');
    }

    showSuccessDialog(context,
        message: '회원가입이 완료되었습니다.',
        onDismiss: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: '회원가입 처리 중...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 학번
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: '학번',
                        border: OutlineInputBorder(),
                        hintText: '학번을 입력하세요',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '학번을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                        hintText: '비밀번호를 입력하세요',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 확인
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호 확인',
                        border: OutlineInputBorder(),
                        hintText: '비밀번호를 다시 입력하세요',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 다시 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 이름
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        border: OutlineInputBorder(),
                        hintText: '이름을 입력하세요',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 전화번호
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '전화번호',
                        border: OutlineInputBorder(),
                        hintText: '전화번호를 입력하세요 (예: 010-1234-5678)',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '전화번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 학과
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: '학과',
                        border: OutlineInputBorder(),
                        hintText: '학과를 입력하세요',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '학과를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 회원가입 버튼
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('회원가입', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
