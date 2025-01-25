import 'package:flutter/material.dart';
import 'bottomNavigationBar.dart';
import 'user_list.dart';
import 'game_record.dart';
import 'settings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: const Text('경상탁구가족'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              print('알림 아이콘 클릭됨');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: 393,
          child: Column(
            children: [
              SizedBox(height: 34),
              Padding(
                padding: const EdgeInsets.only(left: 18.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '즐겨찾기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.27,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '김학생 / 100승 100패 / 승률 50% / 게임수 200회',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '이학생 / 100승 100패 / 승률 50% / 게임수 200회',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '박학생 / 100승 100패 / 승률 50% / 게임수 200회',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '모집 공고',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          height: 1.27,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      print('글쓰기 버튼 클릭됨');
                      // 버튼 클릭 시의 동작 정의
                      // 예: 글쓰기 페이지로 이동
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => const WritePostPage()),
                      // );
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
              Post(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        onTap: (index) {
          // 각 버튼 클릭 시의 동작 정의
          switch (index) {
            case 0:
              // 홈 버튼 클릭 시 아무 동작도 하지 않음
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserListPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GameRecordPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              break;
          }
        },
      ),
    );
  }
}

class Post extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 357,
      height: 176,
      decoration: ShapeDecoration(
        color: Color(0xFFF3EDF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12.0),
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '3월 12일 오후 2시\n동방\n참가자 수: 2 / 4\n김학생, 이학생',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                  letterSpacing: 0.25,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF65558F)),
                        onPressed: () {
                          // 수정 버튼 클릭 시의 동작 정의
                        },
                      ),
                      Text('수정'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Color(0xFF65558F)),
                        onPressed: () {
                          // 삭제 버튼 클릭 시의 동작 정의
                        },
                      ),
                      Text('삭제'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _Post extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 18.0),
//       child: Column(
//         children: [
//           Container(
//             width: 357,
//             height: 176,
//             padding: const EdgeInsets.only(bottom: 8),
//             clipBehavior: Clip.antiAlias,
//             decoration: ShapeDecoration(
//               color: Color(0xFFF3EDF7),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               shadows: [
//                 BoxShadow(
//                   color: Color(0x26000000),
//                   blurRadius: 6,
//                   offset: Offset(0, 2),
//                   spreadRadius: 2,
//                 )
//               ],
//             ),
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 8.0),
//                   child: Text(
//                     '탁구 치실분~ (김학생)',
//                     style: TextStyle(
//                       color: Color(0xFF49454F),
//                       fontSize: 14,
//                       fontFamily: 'Roboto',
//                       fontWeight: FontWeight.w500,
//                       height: 1.43,
//                       letterSpacing: 0.10,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 SizedBox(
//                   width: double.infinity,
//                   child: Text(
//                     '3월 12일 오후 2시\n동방\n참가자 수: 2 / 4\n김학생, 이학생',
//                     style: TextStyle(
//                       color: Color(0xFF49454F),
//                       fontSize: 14,
//                       fontFamily: 'Roboto',
//                       fontWeight: FontWeight.w400,
//                       height: 1.43,
//                       letterSpacing: 0.25,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   height: 40,
//                   clipBehavior: Clip.antiAlias,
//                   decoration: ShapeDecoration(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(100),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.only(
//                             top: 10,
//                             left: 12,
//                             right: 16,
//                             bottom: 10,
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 18,
//                                 height: 18,
//                                 child: FlutterLogo(),
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 '수정',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: Color(0xFF65558F),
//                                   fontSize: 14,
//                                   fontFamily: 'Roboto',
//                                   fontWeight: FontWeight.w500,
//                                   height: 1.43,
//                                   letterSpacing: 0.10,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   height: 40,
//                   clipBehavior: Clip.antiAlias,
//                   decoration: ShapeDecoration(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(100),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.only(
//                             top: 10,
//                             left: 12,
//                             right: 16,
//                             bottom: 10,
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 18,
//                                 height: 18,
//                                 child: FlutterLogo(),
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 '삭제',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: Color(0xFF65558F),
//                                   fontSize: 14,
//                                   fontFamily: 'Roboto',
//                                   fontWeight: FontWeight.w500,
//                                   height: 1.43,
//                                   letterSpacing: 0.10,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
