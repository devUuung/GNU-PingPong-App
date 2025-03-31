import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/utils/dialog_utils.dart';

final supabase = Supabase.instance.client;

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onChangePassword() async {
    if (_formKey.currentState!.validate()) {
      final oldPwd = _oldPasswordController.text.trim();
      final newPwd = _newPasswordController.text.trim();

      if (oldPwd.isEmpty || newPwd.isEmpty) {
        showErrorDialog(context, '비밀번호를 입력해주세요.');
        return;
      }

      // 비밀번호 유효성 검사
      if (newPwd.length < 6) {
        showErrorDialog(context, '새 비밀번호는 최소 6자 이상이어야 합니다.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final User? user = supabase.auth.currentUser;
      if (user == null) {
        showErrorDialog(context, '사용자가 로그인되어 있지 않습니다.');
        return;
      }

      await supabase.auth.updateUser(
        UserAttributes(password: newPwd),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 공용 AppBar를 쓰는 경우 CommonAppBar 등으로 대체하면 됩니다.
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
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
              // 현재 비밀번호
              const Text('현재 비밀번호',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '기존 비밀번호를 입력하세요.',
                ),
              ),
              const SizedBox(height: 20),

              // 새 비밀번호
              const Text('새 비밀번호',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '새 비밀번호를 입력하세요.',
                ),
              ),
              const SizedBox(height: 40),

              // 변경 버튼
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _onChangePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          backgroundColor:
                              const Color.fromRGBO(101, 85, 143, 1), // 수정된 부분
                        ),
                        child: const Text(
                          '변경',
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
