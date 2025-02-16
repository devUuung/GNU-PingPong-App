import 'package:flutter/material.dart';
import 'package:flutter_app/user_list.dart';
import 'package:flutter_app/game_record.dart';
import 'package:flutter_app/settings.dart';
import 'package:flutter_app/recruit_post.dart';

// 공통 AppBar import
import 'package:flutter_app/widgets/app_bar.dart';
// 새로 만든 공통 BottomNavigationBar
import 'package:flutter_app/widgets/bottom_bar.dart';

// 새로 만든 수정 화면 import
import 'package:flutter_app/recruit_edit.dart'; // ★ 이 라인을 추가해 주세요
import 'package:flutter_app/widgets/post.dart';

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
                                builder: (context) => const RecruitPostPage(),
                              ),
                            );
                          },
                          child: const Text(
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
                Center(child: Post()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const CommonBottomNavigationBar(currentPage: "home"),
    );
  }
}
