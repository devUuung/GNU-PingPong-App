import 'package:flutter/material.dart';
import 'package:flutter_app/screens/alarm.dart';

/// 여러 페이지에서 공통으로 사용하는 AppBar 위젯
/// 현재 페이지를 문자열 currentPage로 받아서, 페이지별로 액션 로직을 달리할 수 있음
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentPage; // "home", "userList", "settings" 등으로 구분
  final bool showNotificationIcon; // 알림 아이콘 표시 여부

  const CommonAppBar({
    Key? key,
    required this.currentPage,
    this.showNotificationIcon = true, // 기본값은 true
  }) : super(key: key);

  // AppBar 기본 높이
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // 알림 아이콘 클릭 시 AlarmPage로 이동
  void _onNotificationPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlarmPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Align(
        alignment: Alignment.center,
        child: Text('경상탁구가족'),
      ),
      actions: [
        if (showNotificationIcon) // 알림 아이콘 표시 여부에 따라 조건부 렌더링
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _onNotificationPressed(context),
          ),
      ],
    );
  }
}
