import 'package:flutter/material.dart';
import 'package:flutter_app/home.dart'; // 홈 화면
import 'package:flutter_app/user_list.dart'; // 회원목록 화면
import 'package:flutter_app/game_record.dart'; // 경기기록 화면
import 'package:flutter_app/settings.dart'; // 설정 화면

/// 공통 BottomNavigationBar 위젯
class CommonBottomNavigationBar extends StatelessWidget {
  final String currentPage;
  // 예: "home", "userList", "gameRecord", "settings" 등으로 구분

  const CommonBottomNavigationBar({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: // 홈
        // 이미 홈이면 아무 동작도 안 할 수도 있고,
        // 혹은 pushReplacement를 통해 홈으로 이동할 수도 있음
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1: // 회원목록
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserListPage()),
        );
        break;
      case 2: // 경기기록
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamesPage()),
        );
        break;
      case 3: // 설정
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyInfoPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 페이지에 맞춰 bottomNavigationBar의 선택 index를 결정
    int selectedIndex;
    switch (currentPage) {
      case "home":
        selectedIndex = 0;
        break;
      case "userList":
        selectedIndex = 1;
        break;
      case "gameRecord":
        selectedIndex = 2;
        break;
      case "settings":
        selectedIndex = 3;
        break;
      default:
        selectedIndex = 0; // 기본값
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '회원목록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_tennis),
          label: '경기기록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '설정',
        ),
      ],
    );
  }
}
