// lib/screens/settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/change_password.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/screens/profile_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common/loading_indicator.dart';

final supabase = Supabase.instance.client;

class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  bool _alarmEnabled = true;
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownError) {
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        showErrorDialog(context, '사용자가 로그인되어 있지 않습니다.');
        _hasShownError = true;
      }
    }
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    try {
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      final response = await supabase
          .from('userinfo')
          .select('*')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() {
        _userInfo = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, '사용자 정보를 불러오는 중 오류가 발생했습니다: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      if (mounted) {
        _loadUserInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "settings",
        showNotificationIcon: false,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: '프로필 정보를 불러오는 중...')
          : _userInfo == null
              ? const Center(child: Text('사용자 정보를 불러올 수 없습니다.'))
              : SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF7FF),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileHeader(
                          userName: _userInfo!['username'] ?? 'None',
                          userId: _userInfo!['id'] ?? '',
                          statusMessage: _userInfo!['status'] ?? 'None',
                        ),
                        const SizedBox(height: 20),
                        InfoRow(label: '전공', value: _userInfo!['department']),
                        InfoRow(
                            label: '학번', value: '${_userInfo!['student_id']}'),
                        InfoRow(
                            label: '부수 / 승점',
                            value:
                                '${_userInfo!['rank']}부 / ${_userInfo!['custom_point']}'),
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
                        SettingsListItem(
                          title: '로그아웃',
                          onTap: () => _signOut(),
                        ),
                        const SettingsListItem(title: '그 외 항목2'),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar:
          const CommonBottomNavigationBar(currentPage: "settings"),
    );
  }

  Future<void> _signOut() async {
    if (!mounted) return;

    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, '로그아웃 중 오류가 발생했습니다: $e');
    }
  }
}

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String statusMessage;
  final String userId;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userId,
    this.statusMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("ProfileHeader build called for user ID: $userId");
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
            child: (userId.isNotEmpty)
                ? FutureBuilder<String>(
                    future: () {
                      final imagePath = 'public/$userId.png';
                      debugPrint("ProfileHeader trying path: $imagePath");
                      return supabase.storage
                          .from('avatars')
                          .createSignedUrl(imagePath, 60);
                    }(),
                    builder: (context, snapshot) {
                      debugPrint(
                          "ProfileHeader FutureBuilder state: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}");
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        debugPrint(
                            "ProfileHeader FutureBuilder Error or No Data: ${snapshot.error}");
                        return const Icon(Icons.person,
                            size: 40, color: Colors.grey);
                      }
                      final imageUrl = snapshot.data!;
                      debugPrint("ProfileHeader Image URL: $imageUrl");
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              "Error loading header profile image: $error");
                          return const Icon(Icons.person,
                              size: 40, color: Colors.grey);
                        },
                      );
                    },
                  )
                : const Icon(Icons.person, size: 40, color: Colors.grey),
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
    super.key,
    required this.label,
    required this.value,
  });

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
    super.key,
    required this.title,
    this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
    this.onToggleChanged,
  });

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
