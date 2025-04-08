import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class VersionInfo {
  final String version;
  final bool required;
  final String? message;
  final String? androidLink;
  final String? iosLink;

  VersionInfo({
    required this.version,
    required this.required,
    this.message,
    this.androidLink,
    this.iosLink,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] ?? '',
      required: json['required'] ?? false,
      message: json['message'],
      androidLink: json['android_link'],
      iosLink: json['ios_link'],
    );
  }
}

// Supabase 클라이언트 인터페이스
abstract class SupabaseClientInterface {
  Future<Map<String, dynamic>?> getLatestVersionData();
}

// 실제 프로덕션 환경에서 사용할 Supabase 클라이언트 구현
class RealSupabaseClient implements SupabaseClientInterface {
  final SupabaseClient _client;

  RealSupabaseClient(this._client);

  factory RealSupabaseClient.fromInstance() {
    try {
      return RealSupabaseClient(Supabase.instance.client);
    } catch (e) {
      debugPrint('Supabase 인스턴스 접근 오류: $e');
      throw Exception('Supabase가 초기화되지 않았습니다.');
    }
  }

  @override
  Future<Map<String, dynamic>?> getLatestVersionData() async {
    try {
      final response = await _client
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      return response;
    } catch (e) {
      debugPrint('버전 정보를 가져오는 중 오류 발생: $e');
      return null;
    }
  }
}

// 테스트 환경에서 사용할 Mock 클라이언트
class MockSupabaseClient implements SupabaseClientInterface {
  @override
  Future<Map<String, dynamic>?> getLatestVersionData() async {
    // 테스트용 더미 데이터 반환
    return {
      'version': '1.0.0',
      'required': false,
      'message': '테스트 버전',
      'android_link': 'market://details?id=com.gnu.pingpong',
      'ios_link': 'https://apps.apple.com/app/id앱ID',
    };
  }
}

class VersionCheck {
  static VersionCheck? _instance;
  final SupabaseClientInterface _supabaseClient;

  factory VersionCheck({SupabaseClientInterface? supabaseClient}) {
    if (supabaseClient != null) {
      return VersionCheck._custom(supabaseClient);
    }

    _instance ??= VersionCheck._createInstance();
    return _instance!;
  }

  static VersionCheck _createInstance() {
    try {
      return VersionCheck._internal(RealSupabaseClient.fromInstance());
    } catch (e) {
      // Supabase 초기화가 안 된 환경(테스트 등)에서는 Mock 클라이언트 사용
      debugPrint('테스트 환경으로 감지하여 Mock 클라이언트를 사용합니다: $e');
      return VersionCheck._internal(MockSupabaseClient());
    }
  }

  VersionCheck._internal(this._supabaseClient);

  VersionCheck._custom(this._supabaseClient);

  // 서버에서 최신 버전 정보를 가져옵니다
  Future<VersionInfo?> getLatestVersion() async {
    final response = await _supabaseClient.getLatestVersionData();
    if (response != null) {
      return VersionInfo.fromJson(response);
    }
    return null;
  }

  // 현재 앱 버전과 최신 버전을 비교합니다
  Future<bool> needsUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final latestVersionInfo = await getLatestVersion();

    if (latestVersionInfo == null) return false;
    final latestVersion = latestVersionInfo.version;

    // 버전 비교 로직 (semver 형식 가정: x.y.z)
    return compareVersions(currentVersion, latestVersion);
  }

  // 업데이트 필요 시 다이얼로그를 표시합니다
  Future<void> checkForUpdate(BuildContext context) async {
    final latestVersionInfo = await getLatestVersion();
    if (latestVersionInfo == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 버전 비교
    final isUpdateNeeded =
        compareVersions(currentVersion, latestVersionInfo.version);

    if (isUpdateNeeded) {
      // ignore: use_build_context_synchronously
      showUpdateDialog(context, latestVersionInfo);
    }
  }

  // 버전을 비교합니다 - 테스트를 위해 public으로 변경
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

  // 업데이트 다이얼로그를 표시합니다
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
              _launchAppStore(versionInfo);
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  // 앱 스토어로 이동합니다
  Future<void> _launchAppStore(VersionInfo versionInfo) async {
    String storeUrl;

    if (Platform.isAndroid) {
      // 안드로이드 플레이스토어 링크
      storeUrl =
          versionInfo.androidLink ?? 'market://details?id=com.gnu.pingpong';
    } else if (Platform.isIOS) {
      // iOS 앱스토어 링크
      storeUrl = versionInfo.iosLink ?? 'https://apps.apple.com/app/id앱ID';
    } else {
      // 웹 또는 기타 플랫폼
      storeUrl =
          'https://play.google.com/store/apps/details?id=com.gnu.pingpong';
    }

    final Uri uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // 플레이스토어가 실행되지 않으면 웹으로 열기
      final Uri webUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.gnu.pingpong');
      await launchUrl(webUri);
    }
  }
}
