import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_bar.dart';
import 'bottom_bar.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // 기존 프로필 데이터 (예시)
  final _nicknameController = TextEditingController(text: '김학생');
  final _statusMessageController =
      TextEditingController(text: '안녕하십니까. 뉴비입니다 잘부탁드립니다.');

  // 선택된 프로필 이미지 (갤러리에서 선택)
  File? _profileImageFile;

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  /// “프로필 이미지 변경” 버튼 → 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
    }
  }

  /// “저장하기” 버튼
  void _onSaveProfile() {
    final nickname = _nicknameController.text.trim();
    final statusMsg = _statusMessageController.text.trim();

    if (nickname.isEmpty) {
      _showErrorDialog('닉네임을 입력해주세요.');
      return;
    }

    // TODO: 서버/DB에 업데이트 로직
    //  1) 프로필 이미지 _profileImageFile
    //  2) 닉네임 nickname
    //  3) 상태메시지 statusMsg

    debugPrint('닉네임: $nickname');
    debugPrint('상태 메시지: $statusMsg');
    debugPrint('선택된 이미지: ${_profileImageFile?.path}');

    // 저장 성공 시
    Navigator.pop(context); // 이전 화면으로 돌아가는 예시
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
      // 공용 AppBar (프로젝트 상황에 맞게 교체 가능)
      appBar: const CommonAppBar(
        currentPage: "editProfile",
      ),
      backgroundColor: const Color(0xFFFEF7FF),

      // 필요하다면 bottomNavigationBar도 추가 가능
      // bottomNavigationBar: const CommonBottomNavigationBar(currentPage: "editProfile"),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
              // 1) 프로필 이미지
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // 기존 이미지 or 갤러리 선택 이미지 표시
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageFile == null
                          ? const NetworkImage('https://picsum.photos/200')
                          : FileImage(_profileImageFile!) as ImageProvider,
                    ),

                    // 변경 버튼 아이콘
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF65558F),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2) 닉네임
              const Text(
                '닉네임',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 김학생',
                ),
              ),
              const SizedBox(height: 16),

              // 3) 상태 메시지
              const Text(
                '상태 메시지',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _statusMessageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '한 줄 소개를 입력하세요.',
                ),
              ),
              const SizedBox(height: 24),

              // 저장하기 버튼
              Center(
                child: ElevatedButton(
                  onPressed: _onSaveProfile,
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
                    '저장하기',
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
