// lib/screens/settings.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/api_config.dart';
import 'package:flutter_app/screens/change_password.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/screens/profile_edit.dart';
import 'package:flutter_app/dialog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_app/services/token_service.dart';
import 'package:flutter_app/screens/login.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({Key? key}) : super(key: key);

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  // 모집공고 알림 토글 초기 상태
  bool _alarmEnabled = true;

  // 기본 프로필 이미지 URL
  final String _defaultProfileImageUrl =
      '${ApiConfig.baseUrl}/static/default_profile.png';

  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 사용자 정보를 가져옵니다
    // BuildContext를 전달하지 않고 Provider 호출
    Future.microtask(() {
      if (mounted) {
        Provider.of<UsersInfoProvider>(context, listen: false).fetchUserInfo();
      }
    });
  }

  void _onChangePassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  void _onEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    ).then((_) {
      // 프로필 수정 후 돌아오면 사용자 정보 다시 불러오기
      // BuildContext를 전달하지 않고 Provider 호출
      if (mounted) {
        Future.microtask(() {
          Provider.of<UsersInfoProvider>(context, listen: false)
              .fetchUserInfo();
        });
      }
    });
  }

  // JWT 및 사용자 정보 삭제 기능
  Future<void> _deleteJWT() async {
    final storage = FlutterSecureStorage();
    // JWT 토큰 삭제
    await storage.delete(key: 'access_token');

    // 삭제 완료 후 다이얼로그로 알림
    showErrorDialog(context, 'JWT 토큰과 사용자 정보가 삭제되었습니다. 자동 로그인이 비활성화되었습니다.');

    // 선택 사항: 로그아웃 처리 후 로그인 화면으로 이동
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "settings",
        showNotificationIcon: false,
      ),
      body: Consumer<UsersInfoProvider>(
        builder: (context, usersInfoProvider, child) {
          // 로딩 중일 때 로딩 인디케이터 표시
          if (usersInfoProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('사용자 정보를 불러오는 중...'),
                ],
              ),
            );
          }

          // 사용자 정보가 없을 때 메시지 표시
          final userInfo = usersInfoProvider.userInfo;
          if (userInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('사용자 정보를 불러올 수 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // BuildContext를 전달하지 않고 Provider 호출
                      Provider.of<UsersInfoProvider>(context, listen: false)
                          .fetchUserInfo();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 프로필 이미지 URL 가져오기 (없으면 기본 이미지 사용)
          final String profileImageUrl =
              userInfo.profileImageUrl ?? _defaultProfileImageUrl;

          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFEF7FF),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    userName: userInfo.username ?? 'None',
                    profileImageUrl: profileImageUrl,
                    statusMessage: userInfo.statusMessage ?? 'None',
                  ),
                  const SizedBox(height: 20),
                  // 사용자 기본 정보 (예시)
                  const InfoRow(label: '전공', value: 'None'),
                  InfoRow(label: '학번', value: '${userInfo.studentId}'),
                  InfoRow(
                      label: '부수 / 승점',
                      value: '${userInfo.rank}부 / ${userInfo.customPoint}'),
                  // 메뉴 항목들
                  SettingsListItem(
                    title: '비밀번호 재설정',
                    onTap: () => _onChangePassword(context),
                  ),
                  SettingsListItem(
                    title: '프로필 수정',
                    onTap: () => _onEditProfile(context),
                  ),
                  SettingsListItem(
                    title: '모집공고 알람 듣기(미구현)',
                    isToggle: true,
                    toggleValue: _alarmEnabled,
                    onToggleChanged: (bool val) {
                      setState(() {
                        _alarmEnabled = val;
                      });
                      debugPrint('모집공고 알림 설정: $_alarmEnabled');
                    },
                  ),
                  // JWT 및 사용자 정보 삭제 기능 항목
                  SettingsListItem(
                    title: '로그아웃',
                    onTap: () => _deleteJWT(),
                  ),
                  const SettingsListItem(title: '그 외 항목2'),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          const CommonBottomNavigationBar(currentPage: "settings"),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String statusMessage;
  final String profileImageUrl;

  const ProfileHeader({
    Key? key,
    required this.userName,
    required this.profileImageUrl,
    this.statusMessage = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF65558F),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              profileImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 이미지 로드 실패 시 기본 아이콘 표시
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 텍스트 영역
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요, $userName님',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 왼쪽 라벨, 오른쪽 값으로 구성된 1줄 정보 위젯
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF625B71),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D1B20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 일반 텍스트 메뉴 및 토글 스위치 위젯
class SettingsListItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  const SettingsListItem({
    Key? key,
    required this.title,
    this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
    this.onToggleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isToggle) {
      // 토글 스위치가 포함된 경우
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Switch(
              value: toggleValue,
              onChanged: onToggleChanged,
            ),
          ],
        ),
      );
    } else {
      // 단순 텍스트 메뉴 항목인 경우
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }
  }
}
