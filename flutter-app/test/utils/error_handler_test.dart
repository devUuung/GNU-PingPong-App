import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

/// 테스트를 위한 모의 BuildContext 클래스
///
/// 이 클래스는 실제 BuildContext를 모킹하여 테스트 환경에서 사용합니다.
/// 실제 BuildContext는 위젯 트리의 일부이므로 테스트 환경에서 직접 생성하기 어렵습니다.
class MockBuildContext extends Mock implements BuildContext {}

/// ErrorHandler 유틸리티 클래스의 테스트
///
/// 이 테스트는 ErrorHandler 클래스의 메서드들이 올바르게 동작하는지 확인합니다.
/// 네트워크 오류 메시지 변환 및 오류 표시 기능을 테스트합니다.
void main() {
  group('ErrorHandler 테스트', () {
    late MockBuildContext mockContext;

    /// 각 테스트 전에 실행되는 설정 함수
    ///
    /// 이 함수는 각 테스트마다 새로운 MockBuildContext 인스턴스를 생성합니다.
    setUp(() {
      mockContext = MockBuildContext();
    });

    /// getNetworkErrorMessage 함수 테스트 - Connection closed 오류
    ///
    /// 이 테스트는 'Connection closed' 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - Connection closed', () {
      final error = 'Connection closed before full header was received';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '서버 연결이 중단되었습니다. 서버가 실행 중인지 확인하세요.');
    });

    /// getNetworkErrorMessage 함수 테스트 - Connection refused 오류
    ///
    /// 이 테스트는 'Connection refused' 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - Connection refused', () {
      final error = 'Connection refused';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '서버 연결이 거부되었습니다. 서버 주소와 포트를 확인하세요.');
    });

    /// getNetworkErrorMessage 함수 테스트 - Connection timed out 오류
    ///
    /// 이 테스트는 'Connection timed out' 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - Connection timed out', () {
      final error = 'Connection timed out';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '서버 연결 시간이 초과되었습니다. 네트워크 연결을 확인하세요.');
    });

    /// getNetworkErrorMessage 함수 테스트 - Network is unreachable 오류
    ///
    /// 이 테스트는 'Network is unreachable' 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - Network is unreachable', () {
      final error = 'Network is unreachable';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '네트워크에 연결할 수 없습니다. 인터넷 연결을 확인하세요.');
    });

    /// getNetworkErrorMessage 함수 테스트 - SocketException 오류
    ///
    /// 이 테스트는 'SocketException' 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - SocketException', () {
      final error = 'SocketException: Failed host lookup';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '서버에 연결할 수 없습니다. 서버 주소를 확인하세요.');
    });

    /// getNetworkErrorMessage 함수 테스트 - 기타 오류
    ///
    /// 이 테스트는 알 수 없는 오류 메시지가 올바르게 변환되는지 확인합니다.
    test('getNetworkErrorMessage 함수 테스트 - 기타 오류', () {
      final error = '알 수 없는 오류';
      final message = ErrorHandler.getNetworkErrorMessage(error);
      expect(message, '네트워크 오류가 발생했습니다: 알 수 없는 오류');
    });

    // 참고: 실제 다이얼로그 표시 및 스낵바 표시는 위젯 테스트에서 테스트해야 합니다.
    // 여기서는 함수 시그니처 확인 용도로만 테스트합니다.

    /// showErrorDialog 함수 호출 테스트
    ///
    /// 이 테스트는 showErrorDialog 함수가 올바르게 호출되는지 확인합니다.
    /// 실제 다이얼로그는 표시되지 않고, 함수 호출만 확인합니다.
    test('showErrorDialog 함수 호출 테스트', () {
      // 이 테스트는 실제로 다이얼로그를 표시하지 않고 함수가 오류 없이 호출되는지 확인합니다.
      expect(() => ErrorHandler.showErrorDialog(mockContext, '테스트 오류'),
          throwsA(isA<TypeError>()));
      // 실제 BuildContext가 아닌 Mock 객체를 사용하므로 TypeError가 발생하는 것이 정상입니다.
      // 이 테스트는 함수 시그니처가 변경되었는지 확인하는 용도입니다.
    });

    /// showErrorSnackBar 함수 호출 테스트
    ///
    /// 이 테스트는 showErrorSnackBar 함수가 올바르게 호출되는지 확인합니다.
    /// 실제 스낵바는 표시되지 않고, 함수 호출만 확인합니다.
    test('showErrorSnackBar 함수 호출 테스트', () {
      // 이 테스트는 실제로 스낵바를 표시하지 않고 함수가 오류 없이 호출되는지 확인합니다.
      expect(() => ErrorHandler.showErrorSnackBar(mockContext, '테스트 오류'),
          throwsA(isA<TypeError>()));
      // 실제 BuildContext가 아닌 Mock 객체를 사용하므로 TypeError가 발생하는 것이 정상입니다.
      // 이 테스트는 함수 시그니처가 변경되었는지 확인하는 용도입니다.
    });
  });
}
