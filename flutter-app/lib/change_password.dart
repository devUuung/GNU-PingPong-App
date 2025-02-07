import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _onChangePassword() {
    // TODO: 실제 비밀번호 변경 로직
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }

    // 비밀번호 유효성 검사 등 로직 추가
    debugPrint('현재 비번: $oldPwd / 새 비번: $newPwd');

    // 실제 서버 요청 후 성공 시
    _showMessage('비밀번호가 변경되었습니다.');
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
            const Text('새 비밀번호', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: ElevatedButton(
                onPressed: _onChangePassword,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }
}
