#!/bin/bash

# GNU-PingPong 앱 릴리스 빌드 스크립트
# 사용법: ./scripts/build_release.sh [android|ios|all]

set -e  # 오류 발생 시 스크립트 중단

SCRIPT_DIR=$(dirname "$0")
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_TYPE=${1:-"all"}  # 기본값은 모든 플랫폼 빌드

echo "===== GNU-PingPong 앱 릴리스 빌드 시작 ====="
echo "작업 디렉토리: $APP_DIR"

# 현재 환경 백업
if [ -f "$APP_DIR/.env" ]; then
  echo "기존 .env 파일 백업..."
  cp "$APP_DIR/.env" "$APP_DIR/.env.backup"
fi

# 프로덕션 환경 설정
echo "프로덕션 환경 설정 구성..."

# 환경 변수 로드 (스크립트를 직접 실행하는 경우)
if [ -f "$APP_DIR/.env.prod" ]; then
  echo "기존 .env.prod 파일 사용..."
  cp "$APP_DIR/.env.prod" "$APP_DIR/.env"
else
  echo "새 프로덕션 환경 파일 생성..."
  
  # .env.prod 파일이 없는 경우 사용자에게 입력 요청
  echo "PROD_SUPABASE_URL 입력:"
  read -r PROD_SUPABASE_URL
  echo "PROD_SUPABASE_ANON_KEY 입력:"
  read -r PROD_SUPABASE_ANON_KEY
  
  # 프로덕션 환경 파일 생성
  cat > "$APP_DIR/.env" <<EOL
PROD_SUPABASE_URL=$PROD_SUPABASE_URL
PROD_SUPABASE_ANON_KEY=$PROD_SUPABASE_ANON_KEY
EOL

  # 다음 빌드를 위해 프로덕션 환경 파일 저장
  cp "$APP_DIR/.env" "$APP_DIR/.env.prod"
fi

# Flutter 프로젝트 클린 및 종속성 설치
echo "Flutter 프로젝트 초기화..."
cd "$APP_DIR"
flutter clean
flutter pub get

# Android 빌드
build_android() {
  echo "===== Android 릴리스 빌드 시작 ====="
  flutter build apk --release
  flutter build appbundle --release
  
  # 빌드 결과물 복사
  mkdir -p "$APP_DIR/build/release"
  cp "$APP_DIR/build/app/outputs/flutter-apk/app-release.apk" "$APP_DIR/build/release/gnu_pingpong_app.apk"
  cp "$APP_DIR/build/app/outputs/bundle/release/app-release.aab" "$APP_DIR/build/release/gnu_pingpong_app.aab"
  
  echo "Android 빌드 완료!"
  echo "빌드 결과물: $APP_DIR/build/release/gnu_pingpong_app.apk"
  echo "빌드 결과물: $APP_DIR/build/release/gnu_pingpong_app.aab"
}

# iOS 빌드
build_ios() {
  echo "===== iOS 릴리스 빌드 시작 ====="
  
  # iOS 빌드는 macOS에서만 실행 가능 확인
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "iOS 빌드는 macOS에서만 가능합니다."
    return 1
  fi
  
  # 아카이브 생성
  flutter build ios --release --no-codesign
  
  echo "iOS 빌드 완료!"
  echo "이제 Xcode에서 앱을 Archive하여 App Store Connect에 업로드하세요."
  echo "App Store 배포를 위해 다음 단계를 따르세요:"
  echo "1. Xcode 열기: open ios/Runner.xcworkspace"
  echo "2. Product > Archive 선택"
  echo "3. 아카이브 검증 및 배포"
}

# 선택한 플랫폼에 따라 빌드 실행
case "$BUILD_TYPE" in
  "android")
    build_android
    ;;
  "ios")
    build_ios
    ;;
  "all")
    build_android
    build_ios
    ;;
  *)
    echo "알 수 없는 빌드 타입: $BUILD_TYPE"
    echo "사용법: ./scripts/build_release.sh [android|ios|all]"
    exit 1
    ;;
esac

# 환경 복원
if [ -f "$APP_DIR/.env.backup" ]; then
  echo "환경 설정 복원..."
  mv "$APP_DIR/.env.backup" "$APP_DIR/.env"
fi

echo "===== 빌드 프로세스 완료 =====" 