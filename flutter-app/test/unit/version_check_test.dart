import 'package:flutter/material.dart';
import 'package:gnu_pingpong_app/utils/version_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 테스트용 Mock 클라이언트
class TestMockSupabaseClient implements SupabaseClientInterface {
  final Map<String, dynamic> mockResponse;

  TestMockSupabaseClient(
      {this.mockResponse = const {
        'id': '496453b8-d909-4a88-b9b7-745f22518b38',
        'version': '1.0.0',
        'required': false,
        'message': '테스트 버전',
        'android_link': 'market://details?id=com.gnu.pingpong',
        'ios_link': 'https://apps.apple.com/app/id앱ID',
        'created_at': '2025-04-08T00:00:00Z',
        'updated_at': '2025-04-08T00:00:00Z',
      }});

  @override
  Future<Map<String, dynamic>?> getLatestVersionData() async {
    return mockResponse;
  }
}

void main() {
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

  group('VersionCheck', () {
    test('버전 비교 테스트 - 업데이트 필요 없음', () {
      // 테스트용 의존성 주입
      final mockClient = TestMockSupabaseClient();
      final versionCheck = VersionCheck(supabaseClient: mockClient);

      bool result = versionCheck.compareVersions('1.0.0', '1.0.0');
      expect(result, false);

      result = versionCheck.compareVersions('1.0.1', '1.0.0');
      expect(result, false);

      result = versionCheck.compareVersions('1.1.0', '1.0.0');
      expect(result, false);

      result = versionCheck.compareVersions('2.0.0', '1.0.0');
      expect(result, false);
    });

    test('버전 비교 테스트 - 업데이트 필요', () {
      // 테스트용 의존성 주입
      final mockClient = TestMockSupabaseClient();
      final versionCheck = VersionCheck(supabaseClient: mockClient);

      bool result = versionCheck.compareVersions('1.0.0', '1.0.1');
      expect(result, true);

      result = versionCheck.compareVersions('1.0.0', '1.1.0');
      expect(result, true);

      result = versionCheck.compareVersions('1.0.0', '2.0.0');
      expect(result, true);
    });

    testWidgets('업데이트 다이얼로그 표시 테스트 - 선택적 업데이트', (WidgetTester tester) async {
      // 테스트용 의존성 주입
      final mockClient = TestMockSupabaseClient();
      final versionCheck = VersionCheck(supabaseClient: mockClient);

      final versionInfo = VersionInfo(
        version: '1.1.0',
        required: false,
        message: '업데이트가 있습니다.',
        androidLink: 'market://details?id=com.gnu.pingpong',
        iosLink: 'https://apps.apple.com/app/id앱ID',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    versionCheck.showUpdateDialog(context, versionInfo);
                  },
                  child: const Text('업데이트 확인'),
                );
              },
            ),
          ),
        ),
      );

      // 버튼 클릭
      await tester.tap(find.text('업데이트 확인'));
      await tester.pumpAndSettle();

      // 다이얼로그 표시 확인
      expect(find.text('업데이트 필요'), findsOneWidget);
      expect(find.text('업데이트가 있습니다.'), findsOneWidget);
      expect(find.text('나중에'), findsOneWidget);
      expect(find.text('업데이트'), findsOneWidget);
    });

    testWidgets('업데이트 다이얼로그 표시 테스트 - 필수 업데이트', (WidgetTester tester) async {
      // 테스트용 의존성 주입
      final mockClient = TestMockSupabaseClient();
      final versionCheck = VersionCheck(supabaseClient: mockClient);

      final versionInfo = VersionInfo(
        version: '1.1.0',
        required: true,
        message: '필수 업데이트가 있습니다.',
        androidLink: 'market://details?id=com.gnu.pingpong',
        iosLink: 'https://apps.apple.com/app/id앱ID',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    versionCheck.showUpdateDialog(context, versionInfo);
                  },
                  child: const Text('업데이트 확인'),
                );
              },
            ),
          ),
        ),
      );

      // 버튼 클릭
      await tester.tap(find.text('업데이트 확인'));
      await tester.pumpAndSettle();

      // 다이얼로그 표시 확인
      expect(find.text('업데이트 필요'), findsOneWidget);
      expect(find.text('필수 업데이트가 있습니다.'), findsOneWidget);
      expect(find.text('나중에'), findsNothing); // 필수 업데이트는 '나중에' 버튼이 없어야 함
      expect(find.text('업데이트'), findsOneWidget);
    });

    test('getLatestVersion 테스트', () async {
      // 특정 버전 정보로 모킹
      final mockClient = TestMockSupabaseClient(mockResponse: {
        'version': '1.1.0',
        'required': true,
        'message': '필수 업데이트가 있습니다.',
        'android_link': 'market://details?id=com.gnu.pingpong',
        'ios_link': 'https://apps.apple.com/app/id앱ID',
      });
      final versionCheck = VersionCheck(supabaseClient: mockClient);

      // 메서드 테스트
      final versionInfo = await versionCheck.getLatestVersion();

      // 검증
      expect(versionInfo, isNotNull);
      expect(versionInfo?.version, '1.1.0');
      expect(versionInfo?.required, true);
      expect(versionInfo?.message, '필수 업데이트가 있습니다.');
    });
  });
}
