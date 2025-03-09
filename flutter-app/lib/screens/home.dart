import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_info_provider.dart';
import '../providers/games_info_provider.dart';
import '../providers/star_users_info_provider.dart';
import '../services/user_service.dart';
import '../widgets/common/loading_indicator.dart';
import '../utils/dialog_utils.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/app_bar.dart';
import '../widgets/favorite_users_widget.dart';
import '../widgets/post.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 정보 로드
      final usersProvider =
          Provider.of<UsersInfoProvider>(context, listen: false);
      await usersProvider.fetchCurrentUser();

      // if (usersProvider.currentUser == null) {
      //   // 로그인 화면으로 이동
      //   _navigateToLogin();
      //   return;
      // }

      // 게임 정보 로드
      final gamesProvider =
          Provider.of<GamesInfoProvider>(context, listen: false);
      gamesProvider.fetchAllGames();

      // 즐겨찾기 사용자 정보 로드
      final starUsersProvider =
          Provider.of<StarUsersInfoProvider>(context, listen: false);
      await starUsersProvider.loadStarUsers();
    } catch (e) {
      debugPrint('홈 화면 데이터 로드 중 오류: $e');
      showErrorDialog(context, '데이터를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: '데이터를 불러오는 중...'),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "경상탁구가족",
        showNotificationIcon: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 즐겨찾기 섹션 헤더
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  '즐겨찾기',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    height: 1.27,
                  ),
                ),
              ),
              // 즐겨찾기 위젯
              const FavoriteUsersWidget(),
              const SizedBox(height: 24),
              // 모집 공고 섹션 헤더
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      '모집 공고',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.27,
                      ),
                    ),
                    const SizedBox(width: 12), // 제목과 글쓰기 버튼 사이 간격
                    TextButton(
                      onPressed: () {
                        // 명명된 라우트를 사용하여 글쓰기 화면으로 이동
                        Navigator.pushNamed(context, '/post_create').then((_) {
                          // 게시물 작성 후 화면으로 돌아올 때 데이터 새로고침
                          _loadUserData();
                        });
                      },
                      child: const Text(
                        '글쓰기',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 게시물 위젯 - 가운데 정렬
              const Center(
                child: Post(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(currentPage: "home"),
    );
  }
}
