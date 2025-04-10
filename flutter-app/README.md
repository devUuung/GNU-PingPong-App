# GNU-PingPong-App

경상대학교 경상탁구가족 동아리의 공식 앱입니다.

## 시작하기

### 환경 설정

1. `.env.example` 파일을 `.env`로 복사하고 필요한 환경 변수 값을 입력합니다:
   ```
   PROD_SUPABASE_URL=your_production_supabase_url_here
   PROD_SUPABASE_ANON_KEY=your_production_supabase_anon_key_here
   TEST_SUPABASE_URL=your_test_supabase_url_here
   TEST_SUPABASE_ANON_KEY=your_test_supabase_anon_key_here
   ```

2. 의존성 패키지를 설치합니다:
   ```
   flutter pub get
   ```

### 개발 환경과 프로덕션 환경의 분리

- **개발 및 테스트**: `.env` 파일에 모든 환경 변수(`PROD_*`와 `TEST_*`)를 포함합니다.
- **릴리스 빌드**: 빌드 시 테스트 환경 변수를 제외하고 `PROD_*` 변수만 포함한 `.env` 파일을 사용합니다.

CI/CD 파이프라인은 자동으로 이 과정을 처리합니다.

### 자동화된 릴리스 빌드 스크립트 사용하기

앱 릴리스 빌드를 쉽게 생성하려면 제공된 스크립트를 사용하세요:

```bash
# 모든 플랫폼 빌드
./scripts/build_release.sh

# Android 앱만 빌드
./scripts/build_release.sh android

# iOS 앱만 빌드
./scripts/build_release.sh ios
```

스크립트는 다음과 같은 작업을 수행합니다:
- 프로덕션 환경 변수만 포함된 빌드 환경 설정
- 릴리스 모드로 앱 빌드
- 빌드 결과물을 `build/release` 디렉토리에 저장
- 빌드 후 원래 환경 설정 복원

자세한 내용은 `scripts/README.md`를 참조하세요.

### 수동으로 릴리스 빌드하기

스크립트를 사용하지 않고 수동으로 릴리스 빌드를 생성하려면:

1. 테스트 환경 변수를 제외한 `.env.prod` 파일을 생성합니다:
   ```
   PROD_SUPABASE_URL=your_production_supabase_url_here
   PROD_SUPABASE_ANON_KEY=your_production_supabase_anon_key_here
   ```

2. 빌드 전에 이 파일을 `.env`로 복사합니다:
   ```bash
   cp .env.prod .env
   flutter build apk --release  # 또는 flutter build ios --release
   ```

## 기타 정보

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
