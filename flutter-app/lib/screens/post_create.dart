import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/dialog_utils.dart';

final supabase = Supabase.instance.client;

class PostCreatePage extends StatefulWidget {
  const PostCreatePage({super.key});

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _placeController = TextEditingController();
  final _maxUserController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _placeController.dispose();
    _maxUserController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final place = _placeController.text.trim();
      final maxUserStr = _maxUserController.text.trim();

      if (title.isEmpty || content.isEmpty || place.isEmpty || maxUserStr.isEmpty) {
        showErrorDialog(context, '모든 필드를 입력해주세요.');
        return;
      }

      int? maxUser;
      try {
        maxUser = int.parse(maxUserStr);
        if (maxUser <= 0) {
          showErrorDialog(context, '최대 인원은 1명 이상이어야 합니다.');
          return;
        }
      } catch (e) {
        showErrorDialog(context, '최대 인원에는 숫자만 입력해주세요.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final User? user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        showErrorDialog(context, '사용자가 로그인되어 있지 않습니다.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        await supabase.from('post').insert({
          'title': title,
          'content': content,
          'writer_id': user.id,
          'users': [user.id],
          'place': place,
          'max_user': maxUser,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 생성되었습니다.')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        showErrorDialog(context, '게시글 생성 중 오류가 발생했습니다: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
        backgroundColor: const Color(0xFFFEF7FF),
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('제목', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '제목을 입력하세요.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('내용', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '내용을 입력하세요.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '내용을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('장소', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예: 체육관, 제1학생회관 탁구장 등',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '장소를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('최대 인원', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxUserController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '본인 포함 최대 인원 (숫자만 입력)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
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
              const SizedBox(height: 40),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _createPost();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          backgroundColor:
                              const Color.fromRGBO(101, 85, 143, 1),
                        ),
                        child: const Text(
                          '작성',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
