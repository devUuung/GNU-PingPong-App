import 'dart:io'; // 기기 플랫폼 판별용
import 'dart:convert';
import 'package:flutter/material.dart';

/// 다이얼로그로 에러 메시지 표시
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
