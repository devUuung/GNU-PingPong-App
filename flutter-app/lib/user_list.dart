import 'package:flutter/material.dart';
import 'widgets/bottomNavigationBar.dart';
import 'home.dart'; // 홈
import 'game_record.dart'; // 경기 기록
import 'settings.dart'; // 설정
import 'widgets/bottom_bar.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // 현재 선택된 필터(기본값: '점수')
  String selectedFilter = '점수';

  // "사용자 이름"별로 즐겨찾기(별표) 상태를 저장할 맵
  // 예: {'김학생': false, '이학생': true, ...}
  final Map<String, bool> starStates = {};

  // 샘플 데이터
  final List<Map<String, String>> users = [
    {'name': '김학생', 'score': '3000'},
    {'name': '이학생', 'score': '2500'},
    {'name': '박학생', 'score': '1800'},
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 뒤로가기 버튼 비활성화
      onWillPop: () async => false,
      child: Scaffold(
        // 상단 AppBar
        appBar: AppBar(
          title: const Text('명단'),
          automaticallyImplyLeading: false,
        ),
        // 본문
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 393,
              height: 852,
              decoration: ShapeDecoration(
                color: const Color(0xFFFEF7FF), // 연분홍 배경
                shape: RoundedRectangleBorder(
                  // 테두리 제거, 모서리 둥글게만
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // 필터 버튼 (점수, 게임 수, 승리 수, ...)
                  _buildFilterRow(),
                  // 실제 명단 리스트
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final name = users[index]['name'] ?? '';
                        final score = users[index]['score'] ?? '';
                        return _buildUserItem(name, score);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CommonBottomNavigationBar(
          currentPage: "userList",
        ),
      ),
    );
  }

  /// 필터 버튼들을 가로로 나열하는 Row (혹은 SingleChildScrollView)
  Widget _buildFilterRow() {
    // 표시할 필터 목록
    final filters = ['점수', '게임 수', '승리 수', '패배 수', '점수 폭', '승률'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = (filter == selectedFilter);
          return _buildFilterButton(filter, isSelected);
        }).toList(),
      ),
    );
  }

  /// 필터 버튼 하나. 클릭 시 해당 필터가 선택됨
  Widget _buildFilterButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          // 필터를 변경할 때 원하는 로직(정렬, 검색 등)을 여기서 수행
          print('필터 "$label" 클릭됨');
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8DEF8) : Colors.white,
          border: Border.all(color: const Color(0xFFCAC4D0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF4A4459) : const Color(0xFF49454F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 사용자 리스트의 각 행(프로필, 이름, 점수, 별표 아이콘)
  Widget _buildUserItem(String name, String score) {
    final isStarred = starStates[name] ?? false; // 해당 사용자에 대한 별표 상태
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 프로필 아이콘
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFEADDFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          // 이름
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF1D1B20),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.50,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // 점수
          SizedBox(
            width: 50,
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1D192B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 별표 아이콘
          IconButton(
            icon: Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                starStates[name] = !isStarred;
              });
              // 별 토글될 때마다 원하는 로직 수행
              print('$name 별표 토글: ${starStates[name]}');
            },
          ),
        ],
      ),
    );
  }
}
