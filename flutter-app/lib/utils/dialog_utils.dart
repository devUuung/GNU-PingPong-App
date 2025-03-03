import 'package:flutter/material.dart';

/// 에러 다이얼로그를 표시하는 함수
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('오류'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

/// 확인 다이얼로그를 표시하는 함수
void showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = '확인',
  String cancelText = '취소',
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// 성공 다이얼로그를 표시하는 함수
void showSuccessDialog(
  BuildContext context, {
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('성공'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onDismiss != null) {
              onDismiss();
            }
          },
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
