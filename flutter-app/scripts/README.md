# 릴리스 빌드 스크립트

이 디렉토리에는 GNU-PingPong 앱의 릴리스 빌드를 자동화하는 스크립트가 포함되어 있습니다.

## build_release.sh

이 스크립트는 Android와 iOS용 릴리스 빌드를 생성합니다.

### 기능

- 프로덕션 환경 변수만 포함된 `.env` 파일 생성 (테스트 환경 변수 제외)
- 기존 환경 설정 백업 및 복원
- Android APK 및 App Bundle 생성
- iOS 릴리스 빌드 생성
- 빌드 결과물을 `build/release` 디렉토리에 저장

### 사용법

```bash
# 모든 플랫폼 빌드
./scripts/build_release.sh

# Android만 빌드
./scripts/build_release.sh android

# iOS만 빌드
./scripts/build_release.sh ios
```

### 요구 사항

- Android 빌드: Flutter SDK 및 Android Studio 설정 필요
- iOS 빌드: macOS, Flutter SDK, Xcode 필요

### 환경 설정

스크립트는 다음과 같은 방법으로 환경 변수를 설정합니다:

1. 기존 `.env.prod` 파일이 있으면 그것을 사용
2. 없는 경우 사용자에게 필요한 환경 변수 입력 요청
3. 입력받은 환경 변수를 `.env.prod`에 저장하여 다음 실행 시 재사용

### iOS 배포 안내

iOS 빌드 후에는 다음 단계를 거쳐 App Store에 업로드할 수 있습니다:

1. Xcode 열기: `open ios/Runner.xcworkspace`
2. Product > Archive 선택
3. Organizer에서 아카이브 검증 및 배포

### 주의 사항

- 스크립트가 끝나면 원래 `.env` 파일로 복원됩니다.
- `.env.prod` 파일에는 민감한 정보가 포함되므로 버전 관리에 추가하지 마세요. 