import 'package:flutter/material.dart';
import 'win_lost_select.dart';

class FindUserPage extends StatelessWidget {
  FindUserPage({Key? key}) : super(key: key);

  // 학생 목록 (동적으로 변할 수도 있음)
  final List<String> students = [
    '전학생',
    '박학생',
    '이학생',
    '김학생',
    '고학생',
    '최학생',
    '정학생',
    '윤학생',
    '류학생',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 AppBar
      appBar: AppBar(
        title: const Text('주변 사람 찾는중..'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
      ),
      // 화면 전체 배경색
      backgroundColor: const Color(0xFFFEF7FF),

      // 2명씩 한 줄, 세로 스크롤 가능
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFEF7FF),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 한 행에 2명
              crossAxisSpacing: 20, // 컬럼 간 간격
              mainAxisSpacing: 20, // 행 간 간격
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              // 학생 이름
              final studentName = students[index];
              // _buildStudentItem 호출 시 context를 넘겨주어 push 사용
              return _buildStudentItem(context, studentName);
            },
          ),
        ),
      ),

      // 하단 안내 문구
      bottomNavigationBar: Container(
        color: const Color(0xFFFEF7FF),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: const Text(
          '블루투스가 켜져있는지 확인해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1D1B20),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// (1) 학생 아이콘 + 이름 + 탭 이벤트
  Widget _buildStudentItem(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        // (2) 탭 시 UserDetailPage로 이동, 이름 전달
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WinLoseSelect(myName: name, otherName: name),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 60,
            color: Colors.black54,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
