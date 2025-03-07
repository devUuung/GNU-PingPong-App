// lib/screens/user_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/screens/home.dart'; // 홈 화면
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_app/providers/star_users_info_provider.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // 현재 선택된 필터 (기본값: '점수')
  String selectedFilter = '점수';

  @override
  void initState() {
    super.initState();
    // Provider를 통해 모든 유저 정보를 불러옵니다.
    Future.microtask(() {
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUsersInfo(context);
    });
  }

  /// 선택된 필터에 따라 유저 객체에서 표시할 값을 반환합니다.
  String getUserValue(Map<String, dynamic> user) {
    switch (selectedFilter) {
      case '점수':
        return user['score']?.toString() ?? '';
      case '게임 수':
        return user['game_count']?.toString() ?? '';
      case '승리 수':
        return user['win_count']?.toString() ?? '';
      case '패배 수':
        return user['lose_count']?.toString() ?? '';
      case '점수 폭':
        return (user['score'] - user['initial_score']).toString();
      case '승률':
        if (user['game_count'] == 0) {
          return '0%';
        }
        double winRate = (user['win_count'] / user['game_count']) * 100;
        return winRate.toStringAsFixed(2) + '%';
      default:
        return user['score']?.toString() ?? '';
    }
  }

  // 유저 프로필 팝업을 표시하는 함수
  void _showUserProfile(BuildContext context, Map<String, dynamic> user) {
    // 승률 계산
    String winRate = '0%';
    if (user['game_count'] != null && user['game_count'] > 0) {
      double rate = (user['win_count'] / user['game_count']) * 100;
      winRate = rate.toStringAsFixed(2) + '%';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 프로필 이미지
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF65558F), width: 2),
                  ),
                  child: ClipOval(
                    child: user['profile_image_url'] != null &&
                            user['profile_image_url'].isNotEmpty
                        ? Image.network(
                            user['profile_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person,
                                    size: 60, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.person,
                            size: 60, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // 사용자 이름
                Text(
                  user['username'] ?? '이름 없음',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                  ),
                ),

                // 상태 메시지
                if (user['status_message'] != null &&
                    user['status_message'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      user['status_message'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF49454F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // 사용자 정보 테이블
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.5),
                  },
                  children: [
                    _buildTableRow(
                        '학번', user['student_id']?.toString() ?? '정보 없음'),
                    _buildTableRow('점수', user['score']?.toString() ?? '0'),
                    _buildTableRow(
                        '게임 수', user['game_count']?.toString() ?? '0'),
                    _buildTableRow(
                        '승리 수', user['win_count']?.toString() ?? '0'),
                    _buildTableRow(
                        '패배 수', user['lose_count']?.toString() ?? '0'),
                    _buildTableRow('승률', winRate),
                    _buildTableRow('점수 폭',
                        (user['score'] - user['initial_score']).toString()),
                  ],
                ),

                const SizedBox(height: 24),

                // 닫기 버튼
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65558F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 테이블 행을 생성하는 헬퍼 함수
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF49454F),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1D1B20),
            ),
          ),
        ),
      ],
    );
  }

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
        // Provider를 이용하여 유저 정보를 불러옴
        body: Consumer<UsersInfoProvider>(
          builder: (context, usersProvider, child) {
            if (usersProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 오류 메시지가 있는 경우 표시
            if (usersProvider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        usersProvider.error!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Provider에서 불러온 유저 목록 (캐시 혹은 API에서 불러온 데이터)
            var users = usersProvider.users ?? [];

            // 현재 로그인한 사용자가 있고, 목록에 없는 경우 추가
            if (usersProvider.currentUser != null) {
              bool containsCurrentUser = users.any(
                  (user) => user.userId == usersProvider.currentUser!.userId);

              if (!containsCurrentUser) {
                users = [...users, usersProvider.currentUser!];
              }
            }

            return SingleChildScrollView(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
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
                      // 필터 버튼 영역 (예: 점수, 게임 수, 승리 수 등)
                      _buildFilterRow(),
                      // 실제 사용자 명단 리스트
                      Expanded(
                        child: users.isEmpty
                            ? const Center(
                                child: Text(
                                  '사용자 목록이 비어 있습니다.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF49454F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return _buildUserItem(user.toJson());
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
          // 필터 변경 시 원하는 추가 로직 수행
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

  /// 사용자 리스트의 각 행(프로필, 이름, 선택된 필터에 따른 값, 별표 아이콘)
  Widget _buildUserItem(Map<String, dynamic> user) {
    final String name = user['username'] ?? '';
    final String value = getUserValue(user);
    // StarUsersInfoProvider를 통해 별표 여부를 확인합니다.
    final starUsersProvider = Provider.of<StarUsersInfoProvider>(context);
    final bool isStarred = starUsersProvider.isStarred(user);
    // 프로필 이미지 URL 가져오기
    final String profileImageUrl = user['profile_image_url'] ?? '';

    return InkWell(
      onTap: () => _showUserProfile(context, user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 프로필 이미지
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFEADDFF),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFF65558F), width: 1),
              ),
              child: ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지 로드 실패 시 기본 아이콘 표시
                          return const Icon(Icons.person,
                              color: Colors.black54);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.person, color: Colors.black54),
              ),
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
            // 선택된 필터에 따른 값 표시
            SizedBox(
              width: 50,
              child: Text(
                value,
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
                // 별표 버튼 클릭 시, StarUsersInfoProvider에 유저 토글 (추가/제거)
                starUsersProvider.toggleStarUser(user);
                // 변경 사항 반영을 위해 setState() 호출 (Provider 내부에서 notifyListeners() 호출 시 자동 업데이트 될 수도 있음)
                setState(() {});
                print('$name 별표 토글');
              },
            ),
          ],
        ),
      ),
    );
  }
}
