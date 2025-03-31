// lib/screens/games.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_bar.dart';
import 'find_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class GamesPage extends StatefulWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  // 필터 옵션에 "전체", "내 경기", "즐겨찾기" 추가
  final List<String> group1 = ['전체', '내 경기', '즐겨찾기'];
  String selectedFilter = '전체'; // 초기값을 "전체"로 설정
  int? currentUserId; // 현재 사용자 ID 저장

  // 필터에 따라 게임 목록 필터링
  List<dynamic> filterGames(
      List<dynamic> games, String filter, List<dynamic> starUsers) {
    if (filter == '전체') {
      return games;
    } else if (filter == '내 경기') {
      // 현재 사용자가 참여한 경기만 필터링
      return games.where((game) {
        final winnerId = game.winnerId;
        final loserId = game.loserId;
        return winnerId == currentUserId || loserId == currentUserId;
      }).toList();
    } else if (filter == '즐겨찾기') {
      // 즐겨찾기한 사용자가 참여한 경기만 필터링
      return games.where((game) {
        final winnerId = game.winnerId;
        final loserId = game.loserId;
        return starUsers.contains(winnerId) || starUsers.contains(loserId);
      }).toList();
    }
    return games;
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindUserPage()),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.wait([
            supabase.from('game').select('*'),
            supabase
                .from('userinfo')
                .select('star_users')
                .eq('id', supabase.auth.currentUser!.id)
          ]),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final allGames = snapshot.data![0] as List;
            final starUsers = snapshot.data![1] as List;
            final filteredGames =
                filterGames(allGames, selectedFilter, starUsers);

            return SingleChildScrollView(
              child: Container(
                // 원하는 폭을 지정 (예: 393)
                width: 393,
                // 높이는 화면에 맞게 유동적으로 사용
                margin: const EdgeInsets.all(16),
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
                    // 필터 영역 ("전체", "내 경기", "즐겨찾기")
                    _buildFilterRow(),
                    const SizedBox(height: 16),
                    // 헤더 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildGameInfoHeader(),
                    ),
                    // 경기 기록 리스트
                    SizedBox(
                      height: 400, // 고정 높이 설정
                      child: filteredGames.isEmpty
                          ? const Center(
                              child: Text(
                                '표시할 경기 기록이 없습니다.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: filteredGames.length,
                              itemBuilder: (context, index) {
                                final record = filteredGames[index];
                                final id = record.gameId ?? '';
                                final participants =
                                    record.winnerName.toString() +
                                            ' vs ' +
                                            record.loserName.toString() ??
                                        '';
                                final date =
                                    DateTime.parse(record.createdAt.toString())
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16);
                                final winner = record.winnerName ?? '';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: _buildGameItem(
                                    index: index,
                                    id: id.toString(),
                                    participants: participants,
                                    date: date,
                                    winner: winner.toString(),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar:
            const CommonBottomNavigationBar(currentPage: "gameRecord"),
      ),
    );
  }

  /// 필터 영역 ("전체", "내 경기", "즐겨찾기")
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  /// 경기 정보 헤더
  Widget _buildGameInfoHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            '참가자',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '경기날짜',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 1,
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

  /// 경기 기록 리스트 아이템
  Widget _buildGameItem({
    required int index,
    required String id,
    required String participants,
    required String date,
    required String winner,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                participants,
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1D1B20)),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 1,
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
