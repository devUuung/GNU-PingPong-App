import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final Function(int) onTap; // 탭 클릭 시 호출할 함수
  final EdgeInsetsGeometry margin; // margin 추가

  const BottomNavigationBarWidget({
    super.key,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10), // 기본 margin 설정
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin, // margin 적용
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () => onTap(0), // 홈 버튼 클릭 시
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home),
                const Text('홈'),
              ],
            ),
          ),
          InkWell(
            onTap: () => onTap(1), // 명단 버튼 클릭 시
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list),
                const Text('명단'),
              ],
            ),
          ),
          InkWell(
            onTap: () => onTap(2), // 경기기록 버튼 클릭 시
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer),
                const Text('경기기록'),
              ],
            ),
          ),
          InkWell(
            onTap: () => onTap(3), // 설정 버튼 클릭 시
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings),
                const Text('설정'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
