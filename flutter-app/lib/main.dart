import 'package:flutter/material.dart';
import 'login.dart'; // login.dart 파일을 import 합니다.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // 첫 화면을 LoginPage로 설정합니다.
    );
  }
}
