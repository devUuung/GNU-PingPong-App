import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/find_user.dart';

// 경기 기록 페이지
class GamesPage extends StatefulWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  /// 필터: '내 경기', '즐겨찾기'만 남김
  final List<String> group1 = ['내 경기', '즐겨찾기'];
  String selectedFilter = '내 경기'; // 초기값

  // 샘플 데이터 (경기 기록)
  List<Map<String, String>> gameRecords = [
    {
      'id': 'game1',
      'participants': '김학생, 이학생',
      'date': '2023-12-01',
      'location': '체육관 A',
      'winner': '김학생',
    },
    {
      'id': 'game2',
      'participants': '박학생, 최학생',
      'date': '2023-12-02',
      'location': '체육관 B',
      'winner': '최학생',
    },
    {
      'id': 'game3',
      'participants': '김학생, 최학생',
      'date': '2023-12-03',
      'location': '체육관 A',
      'winner': '김학생',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 뒤로가기 버튼 비활성화
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('경기기록'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                // 새 경기 기록 입력 페이지로 이동
                print('경기 기록 입력 버튼 클릭');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindUserPage()),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 393,
              height: 852,
              decoration: ShapeDecoration(
                color: const Color(0xFFFEF7FF), // 연분홍 배경
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ============ 필터 영역 (내 경기, 즐겨찾기만) ============
                  _buildFilterRow(),
                  // ============ 헤더 ============
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildGameInfoHeader(),
                  ),
                  // ============ 리스트 ============
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: gameRecords.length,
                      itemBuilder: (context, index) {
                        final record = gameRecords[index];
                        final id = record['id'] ?? '';
                        final participants = record['participants'] ?? '';
                        final date = record['date'] ?? '';
                        final location = record['location'] ?? '';
                        final winner = record['winner'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildGameItem(
                            index: index,
                            id: id,
                            participants: participants,
                            date: date,
                            location: location,
                            winner: winner,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CommonBottomNavigationBar(
          currentPage: "gameRecord",
        ),
      ),
    );
  }

  /// ==================== 필터(내 경기, 즐겨찾기) ====================
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: group1.map((filter) {
          final isSelected = (filter == selectedFilter);
          return _buildFilterButton(
            label: filter,
            isSelected: isSelected,
            selectedColor: const Color(0xFFCCE5FF), // 하늘색
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
              print('필터 "$filter" 선택됨');
            },
          );
        }).toList(),
      ),
    );
  }

  /// 공용 필터 버튼
  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          border: Border.all(color: const Color(0xFFCAC4D0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF49454F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// ==================== 경기 정보 헤더 ====================
  Widget _buildGameInfoHeader() {
    return Row(
      children: const [
        // 참가자: 왼쪽 정렬
        Expanded(
          child: Text(
            '참가자',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 경기날짜: 중앙 정렬
        Expanded(
          child: Text(
            '경기날짜',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 경기장소: 중앙 정렬
        Expanded(
          child: Text(
            '경기장소',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 이긴 사람: 오른쪽 정렬
        Expanded(
          child: Text(
            '이긴 사람',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// ==================== 스와이프 삭제 리스트 아이템 ====================
  Widget _buildGameItem({
    required int index,
    required String id,
    required String participants,
    required String date,
    required String location,
    required String winner,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart, // 오른쪽 → 왼쪽 스와이프
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          gameRecords.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$id 경기 기록이 삭제되었습니다.')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // 참가자: 왼쪽 정렬, 폰트 16, 검정
            Expanded(
              child: Text(
                participants,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
              ),
            ),
            // 경기날짜: 중앙 정렬, 폰트 14, 회색
            Expanded(
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            // 경기장소: 중앙 정렬, 폰트 14, 회색
            Expanded(
              child: Text(
                location,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            // 이긴 사람: 오른쪽 정렬, 폰트 16, 검정
            Expanded(
              child: Text(
                winner,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1D192B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
