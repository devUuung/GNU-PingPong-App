import 'package:flutter/material.dart';
import 'bottomNavigationBar.dart';
import 'home.dart'; // 홈 화면 임포트
import 'game_record.dart'; // 경기기록 화면 임포트
import 'settings.dart'; // 설정 화면 임포트

class UserListPage extends StatelessWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 버튼 비활성화
      child: Scaffold(
        appBar: AppBar(
          title: const Text('명단'),
          automaticallyImplyLeading: false, // 뒤로가기 아이콘 없애기
        ),
        body: Center(
          child: const Text('명단 화면'),
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
                break;
              case 1:
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GameRecordPage()),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
                break;
            }
          },
        ),
      ),
    );
  }
}
