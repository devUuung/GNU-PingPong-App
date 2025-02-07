import 'package:flutter/material.dart';
import 'package:flutter_app/change_password.dart';
import 'app_bar.dart';
import 'bottom_bar.dart';
import 'edit_profile.dart';

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({Key? key}) : super(key: key);

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  // "모집공고 알람 듣기" 초기 상태
  bool _alarmEnabled = true;

  // 비밀번호 재설정 버튼 클릭 시 ChangePasswordPage로 이동하는 함수
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 기존 프로젝트에서 사용 중인 공용 AppBar (또는 AppBar로 대체)
      appBar: const CommonAppBar(
        currentPage: "settings",
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: const Color(0xFFFEF7FF),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 프로필 영역
              const ProfileHeader(
                userName: '김학생',
                profileImageUrl: 'https://picsum.photos/57',
                statusMessage: '안녕하십니까. 뉴비입니다 잘부탁드립니다.',
              ),
              const SizedBox(height: 20),

              // 사용자 기본 정보 (전공, 학번 등)
              const InfoRow(label: '전공', value: '컴퓨터공학과 컴퓨터과학전공'),
              const InfoRow(label: '학번', value: '2022010808'),
              const InfoRow(label: '등록된 기기', value: '(예: iPhone14-iOS16)'),
              const InfoRow(label: '부수 / 승점', value: 'X부 / 0'),

              // 메뉴 항목들
              SettingsListItem(
                title: '비밀번호 재설정',
                onTap: () => _onChangePassword(context),
              ),
              SettingsListItem(
                title: '프로필 수정',
                onTap: () => _onEditProfile(context),
              ),

              // "모집공고 알람 듣기" 토글
              // toggleValue: _alarmEnabled 상태를 표시
              // onToggleChanged: setState로 _alarmEnabled를 업데이트
              SettingsListItem(
                title: '모집공고 알람 듣기',
                isToggle: true,
                toggleValue: _alarmEnabled,
                onToggleChanged: (bool val) {
                  setState(() {
                    _alarmEnabled = val;
                  });
                  debugPrint('모집공고 알림 설정: $_alarmEnabled');
                  // TODO: 서버/로컬 저장(SharedPreferences 등) 로직 추가
                },
              ),
              const SettingsListItem(title: '그 외 항목1'),
              const SettingsListItem(title: '그 외 항목2'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentPage: "settings",
      ),
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
        CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(profileImageUrl),
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
