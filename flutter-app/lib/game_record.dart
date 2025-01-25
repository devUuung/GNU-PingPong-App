import 'package:flutter/material.dart';
import 'bottomNavigationBar.dart';
import 'home.dart'; // 홈 화면 임포트
import 'user_list.dart'; // 명단 화면 임포트
import 'settings.dart'; // 설정 화면 임포트

class GameRecordPage extends StatelessWidget {
  const GameRecordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 버튼 비활성화
      child: Scaffold(
        appBar: AppBar(
          title: const Text('경기기록'),
          automaticallyImplyLeading: false, // 뒤로가기 아이콘 없애기
        ),
        body: Center(
          child: const Text('경기기록 화면'),
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          onTap: (index) {
            switch (index) {
              case 0:
                // 경기기록 화면에서 홈 버튼 클릭 시 아무 동작도 하지 않음
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserListPage()),
                );
                break;
              case 2:
                // 경기기록 화면에서 경기기록 버튼 클릭 시 아무 동작도 하지 않음
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
