import 'package:flutter/material.dart';
import 'package:flutter_app/recruit_edit.dart';

/// 게시글 위젯
class Post extends StatefulWidget {
  const Post({Key? key}) : super(key: key);

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  /// 삭제 여부를 저장할 플래그
  bool _isDeleted = false;

  @override
  Widget build(BuildContext context) {
    // _isDeleted가 true라면, 완전히 빈 공간으로 대체(SizedBox.shrink).
    if (_isDeleted) {
      return const SizedBox.shrink();
    }

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
            const Text(
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
            const Text(
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

            // 수정/삭제 버튼 Row
            Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF65558F)),
                      onPressed: () {
                        // 수정 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecruitEditPage(),
                          ),
                        );
                      },
                    ),
                    const Text('수정'),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF65558F)),
                      onPressed: () => _confirmDelete(context),
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

  /// 삭제 확인 다이얼로그 표시 후, '예' 선택 시 Post 위젯을 숨김 처리
  Future<void> _confirmDelete(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말로 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // '아니오' → false
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), // '예' → true
              child: const Text('예'),
            ),
          ],
        );
      },
    );

    // 사용자가 '예'를 눌러 result == true라면, _isDeleted를 true로 바꿔서 화면에서 제거
    if (result == true) {
      setState(() {
        _isDeleted = true;
      });
    }
  }
}
