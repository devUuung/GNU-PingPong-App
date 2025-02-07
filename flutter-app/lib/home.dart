import 'package:flutter/material.dart';
import 'user_list.dart';
import 'game_record.dart';
import 'settings.dart';
import 'recruit_post.dart';

// 공통 AppBar import
import 'app_bar.dart';
// 새로 만든 공통 BottomNavigationBar
import 'bottom_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CommonAppBar: 현재 페이지는 "home"
      appBar: const CommonAppBar(currentPage: "home"),

      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 393,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 34),
                const Padding(
                  padding: EdgeInsets.only(left: 18.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '즐겨찾기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.27,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 18.0, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '김학생 / 100승 100패 / 승률 50% / 게임수 200회',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                        letterSpacing: 0.15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
                // ... (나머지 즐겨찾기 목록)
                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 360,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '모집 공고',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            height: 1.27,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            // Navigator.push를 통해 글쓰기 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RecruitPostPage()),
                            );
                          },
                          child: Text(
                            '글쓰기',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontFamily: 'Roboto',
                              height: 1.50,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Center(child: Post()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // 기존 BottomNavigationBarWidget 대신 CommonBottomNavigationBar 적용
      bottomNavigationBar: const CommonBottomNavigationBar(currentPage: "home"),
    );
  }
}

class Post extends StatelessWidget {
  const Post({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 357,
      decoration: ShapeDecoration(
        color: const Color(0xFFF3EDF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          top: 12.0,
          right: 16.0,
          bottom: 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '탁구 치실분~ (김학생)',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: 0.10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '3월 12일 오후 2시\n동방\n참가자 수: 2 / 4\n김학생, 이학생',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: 0.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF65558F)),
                      onPressed: () => print('수정 버튼 클릭됨'),
                    ),
                    const Text('수정'),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF65558F)),
                      onPressed: () => print('삭제 버튼 클릭됨'),
                    ),
                    const Text('삭제'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
