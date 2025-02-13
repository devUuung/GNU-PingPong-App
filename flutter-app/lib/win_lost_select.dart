import 'package:flutter/material.dart';
import 'user_list.dart';

/// 승패 선택 페이지
class WinLoseSelect extends StatefulWidget {
  final String myName; // 내 이름
  final String otherName; // 상대 이름

  const WinLoseSelect({
    Key? key,
    required this.myName,
    required this.otherName,
  }) : super(key: key);

  @override
  State<WinLoseSelect> createState() => _WinLoseSelectState();
}

class _WinLoseSelectState extends State<WinLoseSelect> {
  /// "myName" 혹은 "otherName"을 저장해 두 버튼 중 하나만 선택되도록 한다.
  String? _winnerTag; // 'myName' | 'otherName' | null

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: const Text('둘 중 누가 이겼나요?'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFEF7FF),
        elevation: 0,
      ),
      // 배경색
      backgroundColor: const Color(0xFFFEF7FF),

      // 본문
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 왼쪽 버튼
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(left: 16),
                      child: _buildNameButton(
                        label: widget.myName,
                        tag: 'myName',
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 오른쪽 버튼
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildNameButton(
                        label: widget.otherName,
                        tag: 'otherName',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // 하단 확인 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ElevatedButton(
          onPressed: _winnerTag == null
              ? null
              : () {
                  // 확인 버튼 누르면 UserListPage로 이동 (예시)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserListPage(),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _winnerTag == null ? Colors.grey : Colors.blue,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('확인'),
        ),
      ),
    );
  }

  /// 버튼 생성
  ///  - [label]: 버튼에 보여줄 텍스트 (예: "홍길동")
  ///  - [tag]   : "myName" / "otherName" 등 내부 구분용
  Widget _buildNameButton({
    required String label,
    required String tag,
  }) {
    final bool isSelected = (_winnerTag == tag);

    return GestureDetector(
      onTap: () {
        setState(() {
          // 버튼을 누르면 내 쪽('myName') / 상대 쪽('otherName')으로 구분
          _winnerTag = tag;
        });
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 130, // 최소 가로 길이
          minHeight: 60, // 최소 세로 길이
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: isSelected ? Colors.black : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}
