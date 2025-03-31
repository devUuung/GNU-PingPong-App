import 'package:flutter/material.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/app_bar.dart';
import '../widgets/favorite_users_widget.dart';
import '../widgets/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final bool _isLoading = false;

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
                        Navigator.pushNamed(context, '/post_create');
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
