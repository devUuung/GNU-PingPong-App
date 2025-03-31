import 'package:flutter/material.dart';

/// 네트워크 오류 처리를 위한 유틸리티 클래스
class ErrorHandler {
  /// 네트워크 오류 메시지를 사용자 친화적인 메시지로 변환
  static String getNetworkErrorMessage(dynamic error) {
    if (error
        .toString()
        .contains('Connection closed before full header was received')) {
      return '서버 연결이 중단되었습니다. 서버가 실행 중인지 확인하세요.';
    } else if (error.toString().contains('Connection refused')) {
      return '서버 연결이 거부되었습니다. 서버 주소와 포트를 확인하세요.';
    } else if (error.toString().contains('Connection timed out')) {
      return '서버 연결 시간이 초과되었습니다. 네트워크 연결을 확인하세요.';
    } else if (error.toString().contains('Network is unreachable')) {
      return '네트워크에 연결할 수 없습니다. 인터넷 연결을 확인하세요.';
    } else if (error.toString().contains('SocketException')) {
      return '서버에 연결할 수 없습니다. 서버 주소를 확인하세요.';
    } else {
      return '네트워크 오류가 발생했습니다: $error';
    }
  }

  /// 오류 메시지를 다이얼로그로 표시
  static void showErrorDialog(BuildContext context, dynamic error) {
    final message = getNetworkErrorMessage(error);
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

  /// 오류 메시지를 스낵바로 표시
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getNetworkErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
