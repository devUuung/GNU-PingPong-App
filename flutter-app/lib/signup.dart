import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '학번',
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '이름',
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '전화번호',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '비밀번호',
              ),
              obscureText: true,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 회원가입 로직 추가
                print('회원가입 버튼 클릭됨');
              },
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 로그인 화면으로 돌아가기
              },
              child: const Text('이미 계정이 있으신가요? 로그인하기'),
            ),
          ],
        ),
      ),
    );
  }
}
