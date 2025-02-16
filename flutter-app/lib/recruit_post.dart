import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가
import 'package:flutter/services.dart';

class RecruitPostPage extends StatefulWidget {
  const RecruitPostPage({Key? key}) : super(key: key);

  @override
  State<RecruitPostPage> createState() => _RecruitPostPageState();
}

class _RecruitPostPageState extends State<RecruitPostPage> {
  final _titleController = TextEditingController();
  // 기존 _dateTimeController 대신 날짜/시간 선택을 위한 컨트롤러 사용
  final TextEditingController _dateTimePickerController =
      TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contentController = TextEditingController();

  DateTime? _selectedDateTime; // 날짜와 시간을 함께 관리할 변수

  @override
  void dispose() {
    _titleController.dispose();
    _dateTimePickerController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 날짜와 시간을 선택하는 함수
  Future<void> _pickDateTime() async {
    // 날짜 선택
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    // 시간 선택
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay(
              hour: _selectedDateTime!.hour, minute: _selectedDateTime!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    // 날짜와 시간을 결합하여 하나의 DateTime 객체로 만듦
    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateTimePickerController.text =
          DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
    });
  }

  // “등록하기” 버튼 클릭 시 로직
  void _submitPost() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showErrorDialog('제목을 입력해주세요.');
      return;
    }
    if (_selectedDateTime == null) {
      _showErrorDialog('날짜/시간을 선택해주세요.');
      return;
    }

    final location = _locationController.text.trim();
    final maxPeople = _maxParticipantsController.text.trim();
    final content = _contentController.text.trim();

    debugPrint('제목: $title');
    debugPrint('일시: ${_selectedDateTime.toString()}');
    debugPrint('장소: $location');
    debugPrint('최대 인원: $maxPeople');
    debugPrint('내용: $content');

    // 등록 후 이전 화면으로 돌아가는 예시
    Navigator.pop(context);
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
      appBar: const CommonAppBar(
        currentPage: "recruitPost",
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            // 날짜/시간 - 텍스트 입력이 아닌 선택기로 구현
            const Text(
              '날짜 / 시간',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateTimePickerController,
              readOnly: true, // 직접 입력하지 못하도록 설정
              onTap: _pickDateTime, // 탭 시 날짜/시간 선택기 실행
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '날짜와 시간을 선택하세요',
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // 숫자만 입력하도록 설정
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
                hintText: '예) 같이 치실 분 자유롭게 신청해주세요 :)',
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
    );
  }
}
