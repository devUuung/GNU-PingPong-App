import 'package:flutter/material.dart';
import 'package:gnu_pingpong_app/screens/home.dart'; // 홈 화면
import 'package:gnu_pingpong_app/screens/user_list.dart'; // 회원목록 화면
import 'package:gnu_pingpong_app/screens/games.dart'; // 경기기록 화면
import 'package:gnu_pingpong_app/screens/profile.dart'; // 설정 화면

/// 공통 BottomNavigationBar 위젯
class CommonBottomNavigationBar extends StatelessWidget {
  final String currentPage;
  // 예: "home", "userList", "gameRecord", "settings" 등으로 구분

  const CommonBottomNavigationBar({
    super.key,
    required this.currentPage,
  });

  void _onItemTapped(BuildContext context, int index) {
    // 현재 페이지와 동일한 페이지를 선택한 경우 아무 작업도 하지 않음
    if ((index == 0 && currentPage == "home") ||
        (index == 1 && currentPage == "userList") ||
        (index == 2 && currentPage == "gameRecord") ||
        (index == 3 && currentPage == "settings")) {
      return;
    }

    switch (index) {
      case 0: // 홈
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // 모든 이전 경로 제거
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
