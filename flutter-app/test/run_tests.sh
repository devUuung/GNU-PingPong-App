#!/bin/bash

# Unit tests 실행 (auth_test 제외)
flutter test test/unit/version_check_test.dart

# Widget tests 실행
flutter test test/widget/

# Integration tests 실행
# flutter test integration/

# 인증 테스트는 통합 테스트의 일부로 처리
# flutter test unit/auth_test.dart

# 통합 테스트는 실제 기기나 에뮬레이터에서 실행해야 함
# 아래 명령어는 주석 처리하고, 실제 기기에서 실행 시 사용
# flutter test integration_test/