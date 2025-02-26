import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/dialog.dart';
import 'package:flutter_app/service/token_valid.dart';
import 'package:flutter_app/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

/// 모집 공고 수정 페이지
class RecruitEditPage extends StatefulWidget {
  final int postId;

  const RecruitEditPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<RecruitEditPage> createState() => _RecruitEditPageState();
}

class _RecruitEditPageState extends State<RecruitEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _maxUserController = TextEditingController();
  final _locationController = TextEditingController();
  final TextEditingController _dateTimePickerController =
      TextEditingController();

  DateTime? _selectedDateTime;
  bool _isLoading = true;
  Map<String, dynamic>? _postData;
  int? _currentUserId;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _fetchPostData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _maxUserController.dispose();
    _locationController.dispose();
    _dateTimePickerController.dispose();
    super.dispose();
  }

  // 모집공고 데이터 가져오기
  Future<void> _fetchPostData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 사용자 ID 가져오기
      final tokenResult = await validateToken();
      if (tokenResult['isValid']) {
        _currentUserId = tokenResult['user_id'];
      } else {
        showErrorDialog(context, '로그인이 필요합니다.');
        Navigator.pop(context);
        return;
      }

      // 모집공고 상세 정보 가져오기
      final token = await _secureStorage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/posts/${widget.postId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _postData = responseData['post'];
          _isLoading = false;

          // 폼 필드 초기화
          _titleController.text = _postData!['title'] ?? '';
          _contentController.text = _postData!['content'] ?? '';
          _maxUserController.text = _postData!['max_user'].toString();
          _locationController.text = _postData!['game_place'] ?? '';

          // 날짜 시간 설정
          _selectedDateTime = DateTime.parse(_postData!['game_at']);
          _dateTimePickerController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);

          // 작성자 확인
          if (_postData!['writer_id'] != _currentUserId) {
            showErrorDialog(context, '수정 권한이 없습니다.');
            Navigator.pop(context);
          }
        });
      } else {
        showErrorDialog(
            context, responseData['message'] ?? '모집공고를 불러오는데 실패했습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      showErrorDialog(context, '오류가 발생했습니다: $e');
      Navigator.pop(context);
    }
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

  // 모집공고 수정 요청
  Future<void> _updatePost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 요청 데이터 준비
      final requestData = {
        'post_id': widget.postId,
        'title': _titleController.text.trim(),
        'game_at': _selectedDateTime!.toIso8601String(),
        'game_place': _locationController.text.trim(),
        'max_user': int.parse(_maxUserController.text.trim()),
        'content': _contentController.text.trim(),
        'user_id': _currentUserId,
      };

      // API 요청 보내기
      final token = await _secureStorage.read(key: 'access_token');
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/recruit/post/${widget.postId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      // 응답 처리
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // 성공 시 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모집공고가 수정되었습니다.')),
          );
          Navigator.pop(context); // 이전 화면으로 돌아가기
        }
      } else {
        // 실패 시 처리
        showErrorDialog(context, responseData['message'] ?? '모집공고 수정에 실패했습니다.');
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

  // 입력 검증
  bool _validateInputs() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showErrorDialog(context, '제목을 입력해주세요.');
      return false;
    }

    if (_selectedDateTime == null) {
      showErrorDialog(context, '날짜/시간을 선택해주세요.');
      return false;
    }

    final location = _locationController.text.trim();
    if (location.isEmpty) {
      showErrorDialog(context, '장소를 입력해주세요.');
      return false;
    }

    final maxUser = _maxUserController.text.trim();
    if (maxUser.isEmpty) {
      showErrorDialog(context, '최대 인원을 입력해주세요.');
      return false;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      showErrorDialog(context, '내용을 입력해주세요.');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "recruitEdit",
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      const Text(
                        '제목',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxUserController,
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                      // 수정하기 버튼
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_validateInputs()) {
                                    _updatePost();
                                  }
                                },
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
                                  '수정하기',
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
    );
  }
}
