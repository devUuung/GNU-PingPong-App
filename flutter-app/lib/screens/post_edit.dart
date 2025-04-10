import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/dialog_utils.dart';

final supabase = Supabase.instance.client;

/// 모집 공고 수정 페이지
class RecruitEditPage extends StatefulWidget {
  final String postId;

  const RecruitEditPage({super.key, required this.postId});

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
  String? _currentUserId;
  final _formKey = GlobalKey<FormState>();

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
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        showErrorDialog(context, '로그인이 필요합니다.');
        Navigator.pop(context);
        return;
      }
      _currentUserId = user.id;

      final response = await supabase
          .from('post')
          .select('*')
          .eq('id', widget.postId)
          .single();

      _postData = response;

      if (!mounted) return;

      if (_postData!['writer_id'] != _currentUserId) {
        showErrorDialog(context, '수정 권한이 없습니다.');
        Navigator.pop(context);
        return;
      }

      _titleController.text = _postData!['title'] ?? '';
      _contentController.text = _postData!['content'] ?? '';
      _maxUserController.text = (_postData!['max_user'] ?? 0).toString();
      _locationController.text = _postData!['place'] ?? '';

      if (_postData!['created_at'] != null) {
        try {
          _selectedDateTime = DateTime.parse(_postData!['created_at']);
          _dateTimePickerController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
        } catch (e) {
          debugPrint("Error parsing date: ${_postData!['created_at']} - $e");
          _dateTimePickerController.text = '';
        }
      } else {
        _dateTimePickerController.text = '';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching post data: $e');
      if (!mounted) return;
      showErrorDialog(context, '모집공고를 불러오는 중 오류가 발생했습니다: $e');
      setState(() => _isLoading = false);
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

    if (!mounted) return;

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
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    final maxUser = _maxUserController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('post')
          .update({
            'title': title,
            'place': location,
            'max_user': int.parse(maxUser),
            'content': content,
            'created_at': _selectedDateTime?.toIso8601String(),
          })
          .eq('id', widget.postId)
          .eq('writer_id', _currentUserId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모집공고가 수정되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, '모집공고 수정 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "recruitEdit",
        showNotificationIcon: false,
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
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
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '예) 탁구 치실 분 모집합니다',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '제목을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // 날짜/시간
                        const Text(
                          '날짜 / 시간',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dateTimePickerController,
                          readOnly: true, // 직접 입력하지 못하도록 설정
                          onTap: _pickDateTime, // 탭 시 날짜/시간 선택기 실행
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '날짜와 시간을 선택하세요',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '날짜와 시간을 선택해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // 장소
                        const Text(
                          '장소',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '예) 체육관, 동방 등',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '장소를 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // 최대 인원
                        const Text(
                          '최대 인원',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxUserController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ], // 숫자만 입력하도록 설정
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '예) 4',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '최대 인원을 입력해주세요.';
                            }
                            try {
                              final n = int.parse(value);
                              if (n <= 0) return '1명 이상이어야 합니다.';
                            } catch (e) {
                              return '유효한 숫자를 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // 내용
                        const Text(
                          '내용',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '예) 같이 치실 분 자유롭게 신청해주세요 :)',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '내용을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // 수정하기 버튼
                        Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
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
                ),
          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
