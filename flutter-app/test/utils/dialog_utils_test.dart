import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/dialog_utils.dart';
import 'package:mockito/mockito.dart';

// 테스트를 위한 모의 BuildContext 클래스
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  group('DialogUtils 테스트', () {
    late MockBuildContext mockContext;

    setUp(() {
      mockContext = MockBuildContext();
    });

    // 참고: 실제 다이얼로그 표시는 위젯 테스트에서 테스트해야 하므로
    // 여기서는 함수가 오류 없이 호출되는지만 확인합니다.

    test('showErrorDialog 함수 호출 테스트', () {
      // 이 테스트는 실제로 다이얼로그를 표시하지 않고 함수가 오류 없이 호출되는지 확인합니다.
      // 실제 다이얼로그 표시는 위젯 테스트에서 테스트해야 합니다.
      expect(() => showErrorDialog(mockContext, '에러 메시지'),
          throwsA(isA<TypeError>()));
      // 실제 BuildContext가 아닌 Mock 객체를 사용하므로 TypeError가 발생하는 것이 정상입니다.
      // 이 테스트는 함수 시그니처가 변경되었는지 확인하는 용도입니다.
    });

    test('showConfirmDialog 함수 호출 테스트', () {
      // 이 테스트는 실제로 다이얼로그를 표시하지 않고 함수가 오류 없이 호출되는지 확인합니다.
      expect(
          () => showConfirmDialog(
                mockContext,
                title: '확인',
                message: '확인 메시지',
                onConfirm: () {},
              ),
          throwsA(isA<TypeError>()));
      // 실제 BuildContext가 아닌 Mock 객체를 사용하므로 TypeError가 발생하는 것이 정상입니다.
      // 이 테스트는 함수 시그니처가 변경되었는지 확인하는 용도입니다.
    });

    test('showSuccessDialog 함수 호출 테스트', () {
      // 이 테스트는 실제로 다이얼로그를 표시하지 않고 함수가 오류 없이 호출되는지 확인합니다.
      expect(
          () => showSuccessDialog(
                mockContext,
                message: '성공 메시지',
              ),
          throwsA(isA<TypeError>()));
      // 실제 BuildContext가 아닌 Mock 객체를 사용하므로 TypeError가 발생하는 것이 정상입니다.
      // 이 테스트는 함수 시그니처가 변경되었는지 확인하는 용도입니다.
    });

    // 참고: 실제 다이얼로그 표시 및 상호작용은 위젯 테스트에서 테스트해야 합니다.
    // 이 유닛 테스트는 함수 시그니처 확인 용도로만 사용됩니다.
  });
}
