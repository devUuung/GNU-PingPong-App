import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가
import 'package:intl/date_symbol_data_local.dart'; // 로케일 데이터 초기화를 위해 추가
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/services/token_service.dart';
import 'package:flutter_app/api_config.dart';
import 'package:flutter_app/dialog.dart';

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
  bool _isLoading = false; // 로딩 상태 관리
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // 로케일 데이터 초기화
    initializeDateFormatting('ko_KR');
  }

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

  // 서버에 모집공고 등록 요청을 보내는 함수
  Future<void> _submitPostToServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 토큰 검증을 통해 사용자 ID 가져오기
      final tokenResult = await TokenService().validateToken();

      if (!tokenResult['isValid']) {
        showErrorDialog(context, '로그인이 필요합니다.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = tokenResult['user_id'];
      if (userId == null) {
        showErrorDialog(context, '사용자 정보를 가져올 수 없습니다.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 서버 요청 데이터 준비
      final requestData = {
        'title': _titleController.text.trim(),
        'game_at': _selectedDateTime!.toIso8601String(),
        'game_place': _locationController.text.trim(),
        'max_user': int.parse(_maxParticipantsController.text.trim()),
        'content': _contentController.text.trim(),
        'user_id': userId,
      };

      // API 요청 보내기
      final token = await _secureStorage.read(key: 'access_token');
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(ApiConfig.recruitPost),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestData),
            )
            .timeout(const Duration(seconds: 15));

        // 응답 처리
        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['success'] == true) {
          // 성공 시 처리
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('모집공고가 등록되었습니다.')),
            );
            Navigator.pop(context); // 이전 화면으로 돌아가기
          }
        } else {
          // 실패 시 처리
          showErrorDialog(
              context, responseData['message'] ?? '모집공고 등록에 실패했습니다.');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // 예외 처리
      showErrorDialog(context, '오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // "등록하기" 버튼 클릭 시 로직
  void _submitPost() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      showErrorDialog(context, '제목을 입력해주세요.');
      return;
    }
    if (_selectedDateTime == null) {
      showErrorDialog(context, '날짜/시간을 선택해주세요.');
      return;
    }

    final location = _locationController.text.trim();
    if (location.isEmpty) {
      showErrorDialog(context, '장소를 입력해주세요.');
      return;
    }

    final maxPeople = _maxParticipantsController.text.trim();
    if (maxPeople.isEmpty) {
      showErrorDialog(context, '최대 인원을 입력해주세요.');
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      showErrorDialog(context, '내용을 입력해주세요.');
      return;
    }

    // 서버에 데이터 전송
    _submitPostToServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "recruitPost",
        showNotificationIcon: false,
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    onPressed: _isLoading ? null : _submitPost,
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
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '등록하기',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          const CommonBottomNavigationBar(currentPage: "recruitPost"),
    );
  }
}
