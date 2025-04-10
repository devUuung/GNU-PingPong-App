import 'package:flutter/material.dart';

/// 알림 화면
class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  /// 예시용 가짜 데이터
  /// 실제로는 API 등에서 받아온 알림 목록을 `List<AlarmData>` 형태로 주입
  final List<AlarmData> mockAlarms = const [
    AlarmData(
      title: '회원가입 기능 ON',
      message: '김학생님이 회원가입 기능을 ON 했습니다.',
      time: '01/09 12:30',
      highlighted: true,
    ),
    AlarmData(
      title: '회원가입 기능 OFF',
      message: '김학생님이 회원가입 기능을 OFF 했습니다.',
      time: '01/09 14:50',
    ),
    AlarmData(
      title: '새로운 경기 일정 등록',
      message: '2월 10일에 새로운 경기가 등록되었습니다.',
      time: '02/01 09:12',
    ),
    // 필요 시 더 추가...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 만약 기존 프로젝트에서 쓰는 CommonAppBar를 사용한다면 교체하세요.
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        title: const Text(
          '알림',
          style: TextStyle(color: Color(0xFF1D1B20)),
        ),
        centerTitle: true,
        elevation: 2.0,
      ),
      backgroundColor: const Color(0xFFFEF7FF),

      // ListView로 알림 목록을 표시
      body: ListView.builder(
        itemCount: mockAlarms.length,
        itemBuilder: (context, index) {
          return AlarmItem(alarm: mockAlarms[index]);
        },
      ),

      // 만약 기존 프로젝트에서 이미 사용 중인 바텀 네비게이션을 쓰는 경우:
      // bottomNavigationBar: CommonBottomNavigationBar(currentPage: "alarm"),
    );
  }
}

/// 알림 데이터 모델
class AlarmData {
  final String title;
  final String message;
  final String time;
  final bool highlighted;

  const AlarmData({
    required this.title,
    required this.message,
    required this.time,
    this.highlighted = false,
  });
}

/// 알림 항목 하나를 표시하는 위젯
class AlarmItem extends StatelessWidget {
  final AlarmData alarm;

  const AlarmItem({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    // 하이라이트된 알림일 경우 살짝 배경색을 다르게 할 수 있음
    final bgColor = alarm.highlighted ? const Color(0xFFFFEDF5) : Colors.white;
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 알림 제목
          Text(
            alarm.title,
            style: const TextStyle(
              color: Color(0xFF1D1B20),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.50,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),

          // 알림 본문
          Text(
            '${alarm.message}\n${alarm.time}',
            style: const TextStyle(
              color: Color(0xFF49454F),
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.43,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}
