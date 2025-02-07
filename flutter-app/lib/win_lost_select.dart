import 'package:flutter/material.dart';

// 가정: user_list.dart가 존재하고, UserListPage가 구현되어 있다고 가정
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
  // 현재 선택된 승자 (myName / otherName / null)
  String? _winner;

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // (1) "내 이름" 버튼
            _buildNameButton(widget.myName),
            const SizedBox(height: 20),
            // (2) "상대 이름" 버튼
            _buildNameButton(widget.otherName),
          ],
        ),
      ),

      // 하단 확인 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ElevatedButton(
          onPressed: _winner == null
              ? null
              : () {
                  // (3) 확인 버튼 누르면 UserListPage로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserListPage(),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _winner == null ? Colors.grey : Colors.blue,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('확인'),
        ),
      ),
    );
  }

  /// 이름 버튼 생성: 선택 상태에 따라 색깔/스타일이 달라짐
  Widget _buildNameButton(String name) {
    final bool isSelected = (_winner == name);

    return GestureDetector(
      onTap: () {
        setState(() {
          // 버튼 탭 시 승자를 name으로 설정
          _winner = name;
        });
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: isSelected ? Colors.black : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
