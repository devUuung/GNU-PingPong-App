// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/user_list.dart';
import 'package:flutter_app/screens/games.dart';
import 'package:flutter_app/screens/profile.dart';
import 'package:flutter_app/screens/post_create.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:flutter_app/screens/post_edit.dart';
import 'package:flutter_app/widgets/post.dart';
// 즐겨찾기 위젯 import
import 'package:flutter_app/widgets/favorite_users_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(currentPage: "home"),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 393,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 34),
                // 즐겨찾기 섹션 제목
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
                const SizedBox(height: 10),
                // 즐겨찾기된 유저 목록을 표시하는 위젯
                const FavoriteUsersWidget(),
                const SizedBox(height: 30),
                // 모집 공고 영역
                Center(
                  child: Container(
                    width: 360,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
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
