import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../providers/users_info_provider.dart';
import '../services/token_service.dart';
import 'user_list.dart';
import 'games.dart';
import '../services/user_service.dart';

class WinLoseSelect extends StatefulWidget {
  final String myName;
  final String otherName;
  final int myId;
  final int otherId;

  const WinLoseSelect({
    Key? key,
    required this.myName,
    required this.otherName,
    required this.myId,
    required this.otherId,
  }) : super(key: key);

  @override
  State<WinLoseSelect> createState() => _WinLoseSelectState();
}

class _WinLoseSelectState extends State<WinLoseSelect> {
  /// 'myName' 혹은 'otherName'만 선택되도록 저장
  String? _winnerTag; // 'myName' | 'otherName' | null

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUsersInfo(context);
    });
  }

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
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: Center(
          child: _buildNameButtons(context),
        ),
      ),
      // 하단 확인 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ElevatedButton(
          onPressed: _winnerTag == null
              ? null
              : () async {
                  await _onConfirm(context);
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

  /// 승자를 선택하기 위한 두 개의 버튼을 Row로 구성
  Widget _buildNameButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(left: 16),
                child: Consumer<UsersInfoProvider>(
                  builder: (context, usersInfoProvider, child) {
                    return _buildNameButton(
                      label: widget.myName,
                      tag: 'myName',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
            // 오른쪽 버튼: widget.otherName 사용
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
    );
  }

  /// '확인' 버튼 누르면 실행되는 로직
  Future<void> _onConfirm(BuildContext context) async {
    // 선택 결과에 따라 승자와 패자의 id 결정
    final winnerId = _winnerTag == 'myName' ? widget.myId : widget.otherId;
    final loserId = _winnerTag == 'myName' ? widget.otherId : widget.myId;

    // 점수 변화 값 (필요에 따라 조정 가능)
    const plusScore = 1;
    const minusScore = 1;

    // API를 호출하여 경기 생성
    print('winnerId: $winnerId');
    print('loserId: $loserId');
    print('winnerName: ${widget.myName}');
    print('loserName: ${widget.otherName}');
    print('plusScore: $plusScore');
    print('minusScore: $minusScore');
    bool success = await CreateGameService.createGame(
      winnerId: winnerId,
      loserId: loserId,
      plusScore: plusScore,
      minusScore: minusScore,
    );

    if (success) {
      try {
        await UserService().cancelMatchRequest();
      } catch (e) {
        print('매칭 요청 취소 중 오류: $e');
      }
      // 경기 생성 성공 시 경기기록 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const GamesPage(),
        ),
      );
    } else {
      // 실패 시 스낵바로 오류 메시지 표시
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("경기 생성에 실패했습니다.")),
      );
    }
  }

  /// 각 플레이어 이름 버튼 생성 (라벨/태그를 받아서 만듦)
  Widget _buildNameButton({
    required String label,
    required String tag,
  }) {
    final bool isSelected = (_winnerTag == tag);
    return GestureDetector(
      onTap: () {
        setState(() {
          _winnerTag = tag;
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 130, minHeight: 60),
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
