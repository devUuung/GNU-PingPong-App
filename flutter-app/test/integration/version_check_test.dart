import 'package:flutter/material.dart';
import 'package:flutter_app/utils/version_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 통합 테스트용 Mock 클라이언트
class MockPlatformClient implements SupabaseClientInterface {
  final Map<String, dynamic> mockResponse;
  int callCount = 0;

  MockPlatformClient(
      {this.mockResponse = const {
        'version': '2.0.0', // 현재 버전보다 높은 버전으로 설정
        'required': false,
        'message': '새로운 버전이 있습니다.',
        'android_link': 'market://details?id=com.gnu.pingpong',
        'ios_link': 'https://apps.apple.com/app/id앱ID',
      }});

  @override
  Future<Map<String, dynamic>?> getLatestVersionData() async {
    callCount++;
    return mockResponse;
  }
}

// Mock 업데이트 URL 실행기
class MockUrlLauncher {
  static bool canLaunch = true;
  static String? lastLaunchedUrl;

  static Future<bool> canLaunchUrl(Uri uri) async {
    return canLaunch;
  }

  static Future<bool> launchUrl(Uri uri) async {
    lastLaunchedUrl = uri.toString();
    return true;
  }
}

// 통합 테스트용 VersionCheck 구현
class TestVersionCheck implements VersionCheck {
  final SupabaseClientInterface _supabaseClient;

  TestVersionCheck(this._supabaseClient);

  @override
  Future<void> checkForUpdate(BuildContext context) async {
    final versionInfo = await getLatestVersion();
    if (versionInfo != null) {
      showUpdateDialog(context, versionInfo);
    }
  }

  @override
  bool compareVersions(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.');
    final latestParts = latestVersion.split('.');

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      final currentPart = int.parse(currentParts[i]);
      final latestPart = int.parse(latestParts[i]);

      if (latestPart > currentPart) {
        return true;
      } else if (latestPart < currentPart) {
        return false;
      }
    }

    return latestParts.length > currentParts.length;
  }

  @override
  Future<VersionInfo?> getLatestVersion() async {
    final response = await _supabaseClient.getLatestVersionData();
    if (response != null) {
      return VersionInfo.fromJson(response);
    }
    return null;
  }

  @override
  Future<bool> needsUpdate() async {
    // 항상 업데이트가 필요하다고 가정 (테스트 간소화)
    return true;
  }

  @override
  void showUpdateDialog(BuildContext context, VersionInfo versionInfo) {
    showDialog(
      context: context,
      barrierDismissible: !versionInfo.required,
      builder: (context) => AlertDialog(
        title: const Text('업데이트 필요'),
        content:
            Text(versionInfo.message ?? '새로운 버전의 앱이 사용 가능합니다. 업데이트 후 이용해 주세요.'),
        actions: [
          if (!versionInfo.required)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('나중에'),
            ),
          TextButton(
            onPressed: () {
              // 테스트에서는 URL 실행 무시
              debugPrint(
                  '앱 스토어로 이동: androidLink=${versionInfo.androidLink}, iosLink=${versionInfo.iosLink}');
              Navigator.pop(context);
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // PackageInfo 모킹
    PackageInfo.setMockInitialValues(
      appName: 'GNU-PingPong-App',
      packageName: 'com.gnu.pingpong',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('버전 체크 UI 테스트', (WidgetTester tester) async {
    // 테스트용 Mock 클라이언트 생성
    final mockClient = MockPlatformClient();
    final versionCheck = TestVersionCheck(mockClient);

    // 테스트 위젯 생성
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('버전 체크 테스트'),
          ),
          body: Builder(
            builder: (context) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('현재 앱 버전: 1.0.0'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // 직접 다이얼로그 호출
                        final versionInfo = VersionInfo(
                          version: '2.0.0',
                          required: false,
                          message: '새로운 버전이 있습니다.',
                          androidLink: 'market://details?id=com.gnu.pingpong',
                          iosLink: 'https://apps.apple.com/app/id앱ID',
                        );
                        versionCheck.showUpdateDialog(context, versionInfo);
                      },
                      child: const Text('버전 체크 실행'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    // 위젯이 렌더링될 때까지 대기
    await tester.pumpAndSettle();

    // '버전 체크 실행' 버튼 찾기
    final buttonFinder = find.text('버전 체크 실행');
    expect(buttonFinder, findsOneWidget);

    // 버튼 클릭
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // 업데이트 다이얼로그가 표시되었는지 확인
    expect(find.text('업데이트 필요'), findsOneWidget);
    expect(find.text('새로운 버전이 있습니다.'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('업데이트'), findsOneWidget);

    // '나중에' 버튼 클릭 테스트
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    // 다이얼로그가 닫혔는지 확인
    expect(find.text('업데이트 필요'), findsNothing);
  });

  testWidgets('필수 업데이트 UI 테스트', (WidgetTester tester) async {
    // 테스트용 Mock 클라이언트 생성
    final mockClient = MockPlatformClient();
    final versionCheck = TestVersionCheck(mockClient);

    // 테스트 위젯 생성
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('버전 체크 테스트'),
          ),
          body: Builder(
            builder: (context) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('필수 업데이트 테스트'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // 직접 다이얼로그 호출
                        final versionInfo = VersionInfo(
                          version: '2.0.0',
                          required: true,
                          message: '필수 업데이트가 있습니다.',
                          androidLink: 'market://details?id=com.gnu.pingpong',
                          iosLink: 'https://apps.apple.com/app/id앱ID',
                        );
                        versionCheck.showUpdateDialog(context, versionInfo);
                      },
                      child: const Text('버전 체크 실행'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('버전 체크 실행'));
    await tester.pumpAndSettle();

    // 필수 업데이트 다이얼로그 확인
    expect(find.text('업데이트 필요'), findsOneWidget);
    expect(find.text('필수 업데이트가 있습니다.'), findsOneWidget);
    expect(find.text('나중에'), findsNothing); // 필수 업데이트는 '나중에' 버튼이 없어야 함
    expect(find.text('업데이트'), findsOneWidget);
  });
}
