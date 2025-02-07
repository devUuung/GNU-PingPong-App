import 'package:flutter/material.dart';
import 'app_bar.dart';
import 'bottom_bar.dart';

class RecruitPostPage extends StatefulWidget {
  const RecruitPostPage({Key? key}) : super(key: key);

  @override
  State<RecruitPostPage> createState() => _RecruitPostPageState();
}

class _RecruitPostPageState extends State<RecruitPostPage> {
  // 예시: 작성 화면에 필요한 텍스트필드 컨트롤러들
  final _titleController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _dateTimeController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // “등록하기” 버튼 클릭 시 로직
  void _submitPost() {
    final title = _titleController.text.trim();
    final dateTime = _dateTimeController.text.trim();
    final location = _locationController.text.trim();
    final maxPeople = _maxParticipantsController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showErrorDialog('제목을 입력해주세요.');
      return;
    }
    if (dateTime.isEmpty) {
      _showErrorDialog('날짜/시간을 입력해주세요.');
      return;
    }
    // etc. 나머지 검증...

    // TODO: 서버나 DB에 등록 로직
    debugPrint('제목: $title');
    debugPrint('일시: $dateTime');
    debugPrint('장소: $location');
    debugPrint('최대 인원: $maxPeople');
    debugPrint('내용: $content');

    // 등록 후 페이지 이동 or 메시지 표시
    Navigator.pop(context); // 등록 완료 후 이전 화면으로 돌아가는 예시
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 디자인 일관성을 위해 CommonAppBar 사용
      // (필요에 따라 pageTitle, currentPage 변경 가능)
      appBar: const CommonAppBar(
        currentPage: "recruitPost",
      ),
      backgroundColor: const Color(0xFFFEF7FF),

      // 하단바는 글쓰기 시 굳이 필요 없으면 빼도 됩니다.
      // bottomNavigationBar: const CommonBottomNavigationBar(currentPage: "recruitPost"),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 내부를 라운드 박스(F3EDF7)로 감싸는 예시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  const Text(
                    '제목',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예) 탁구 치실 분 모집합니다',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 날짜/시간
                  const Text(
                    '날짜 / 시간',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateTimeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예) 3월 12일 오후 2시',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 장소
                  const Text(
                    '장소',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예) 체육관, 동방 등',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 최대 인원
                  const Text(
                    '최대 인원',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxParticipantsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예) 4',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 내용
                  const Text(
                    '내용',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예) 현재 김학생, 이학생 2명 신청\n같이 치실 분 자유롭게 신청해주세요 :)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 등록하기 버튼
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF65558F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        '등록하기',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
