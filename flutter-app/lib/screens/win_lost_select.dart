import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'games.dart';

final supabase = Supabase.instance.client;

class WinLoseSelect extends StatefulWidget {
  final String myName;
  final String otherName;
  final int myId;
  final int otherId;

  const WinLoseSelect({
    super.key,
    required this.myName,
    required this.otherName,
    required this.myId,
    required this.otherId,
  });

  @override
  State<WinLoseSelect> createState() => _WinLoseSelectState();
}

class _WinLoseSelectState extends State<WinLoseSelect> {
  /// 'myName' 혹은 'otherName'만 선택되도록 저장
  String? _winnerTag; // 'myName' | 'otherName' | null

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로 가기 버튼 누를 때 매칭 요청 취소하지 않음
        // 사용자가 경기 입력을 계속할 수 있도록 함
        return true;
      },
      child: Scaffold(
        // AppBar
        appBar: AppBar(
          title: const Text('둘 중 누가 이겼나요?'),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
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
                    await _onConfirm();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _winnerTag == null ? Colors.grey : Colors.blue,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('확인'),
          ),
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
                child: _buildNameButton(
                  label: widget.myName,
                  tag: 'myName',
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
  Future<void> _onConfirm() async {
    final winnerId = _winnerTag == 'myName' ? widget.myId : widget.otherId;
    final loserId = _winnerTag == 'myName' ? widget.otherId : widget.myId;
    const plusScore = 1;
    const minusScore = 1;

    try {
      // 게임 기록 생성
      await supabase.from('game').insert({
        'winner_id': winnerId,
        'loser_id': loserId,
        'winner_name':
            _winnerTag == 'myName' ? widget.myName : widget.otherName,
        'loser_name': _winnerTag == 'myName' ? widget.otherName : widget.myName,
      });

      // 승자 점수 업데이트
      await supabase.rpc('update_user_score', params: {
        'user_id': winnerId,
        'score_change': plusScore,
      });

      // 패자 점수 업데이트
      await supabase.rpc('update_user_score', params: {
        'user_id': loserId,
        'score_change': -minusScore,
      });

      // 매칭 요청 삭제 (RPC 함수 사용)
      await supabase.rpc('delete_match', params: {
        'user_uuid': widget.myId.toString(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GamesPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
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
