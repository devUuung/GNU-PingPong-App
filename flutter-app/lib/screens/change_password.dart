import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/api_config.dart';
import 'package:flutter_app/dialog.dart';
import 'package:flutter_app/service/token_valid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onChangePassword() async {
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }

    // 비밀번호 유효성 검사
    if (newPwd.length < 6) {
      _showMessage('새 비밀번호는 최소 6자 이상이어야 합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 토큰 가져오기
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        _showMessage('로그인이 필요합니다.');
        return;
      }

      // 사용자 ID 가져오기
      final tokenData = await validateToken();
      if (!tokenData['isValid'] || tokenData['user_id'] == null) {
        _showMessage('인증에 실패했습니다. 다시 로그인해주세요.');
        return;
      }

      final userId = tokenData['user_id'];

      // 비밀번호 변경 API 요청
      final url = '${ApiConfig.userinfo}/$userId/change-password';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'old_password': oldPwd,
          'new_password': newPwd,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showMessage('비밀번호가 성공적으로 변경되었습니다.');
          // 성공 후 화면 닫기
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        } else {
          _showMessage(data['message'] ?? '비밀번호 변경에 실패했습니다.');
        }
      } else if (response.statusCode == 401) {
        _showMessage('현재 비밀번호가 일치하지 않습니다.');
      } else {
        _showMessage('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('비밀번호 변경 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    );
  }
}
