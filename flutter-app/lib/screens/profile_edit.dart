import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/dialog_utils.dart';

final supabase = Supabase.instance.client;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // 초기값을 별도 변수로 관리하여 변경 여부 비교
  String _initialNickname = '';
  String _initialStatusMsg = '';
  String _avatarImageUrl = '';

  late TextEditingController _nicknameController;
  late TextEditingController _statusMessageController;

  // 갤러리에서 선택된 프로필 이미지 파일 (모바일/데스크톱에서는 path를 사용하고, 웹에서는 XFile와 바이트 데이터를 사용)
  XFile? _avatarImageFile;
  Uint8List? _avatarImageBytes; // 웹 전용 이미지 바이트 데이터

  // 로딩 상태
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _statusMessageController = TextEditingController();

    // 사용자 정보 로드
    _loadUserInfo();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      showErrorDialog(context, '로그인이 필요합니다.');
      return;
    }
    final userInfo =
        await supabase.from('userinfo').select('*').eq('id', user.id).single();

    if (!mounted) return;
    setState(() {
      _initialNickname = userInfo['username'] ?? '';
      _initialStatusMsg = userInfo['status_message'] ?? '';
      _avatarImageUrl = userInfo['avatar_url'] ?? '';

      // 컨트롤러에 초기값 설정
      _nicknameController.text = _initialNickname;
      _statusMessageController.text = _initialStatusMsg;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  /// "프로필 이미지 변경" 버튼 → 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // 웹: 바이트 데이터를 읽어서 저장
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _avatarImageFile = pickedFile;
            _avatarImageBytes = bytes;
          });
        } else {
          // 모바일/데스크톱: XFile의 path 사용
          setState(() {
            _avatarImageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      if (!mounted) return;
      showErrorDialog(context, '이미지를 선택하는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _onSaveProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final newNickname = _nicknameController.text.trim();
    final newStatusMsg = _statusMessageController.text.trim();

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      showErrorDialog(context, '로그인이 필요합니다.');
      return;
    }

    bool changed = false;
    Map<String, String> updatedFields = {};

    // 서버에서는 username으로 업데이트하므로 key 변경
    if (newNickname != _initialNickname) {
      updatedFields["username"] = newNickname;
      changed = true;
    }
    if (newStatusMsg != _initialStatusMsg) {
      updatedFields["status_message"] = newStatusMsg;
      changed = true;
    }
    if (_avatarImageFile != null) {
      final String fullPath = await supabase.storage.from('avatars').update(
            'public/${user.id}.png',
            File(_avatarImageFile!.path),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      updatedFields["avatar_url"] = fullPath;
      changed = true;
    }

    if (!changed) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      showErrorDialog(context, '변경된 정보가 없습니다.');
      return;
    }

    await supabase.from('userinfo').update(updatedFields).eq('id', user.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 수정되었습니다.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "editProfile",
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) 프로필 이미지 영역
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF65558F),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _avatarImageFile != null
                                  ? kIsWeb
                                      ? Image.memory(
                                          _avatarImageBytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          // XFile의 경로를 사용하여 File 객체 생성
                                          File(_avatarImageFile!.path),
                                          fit: BoxFit.cover,
                                        )
                                  : Image.network(
                                      _avatarImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // 이미지 로드 실패 시 기본 아이콘 표시
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
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
                                padding: const EdgeInsets.all(8),
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
                    // 2) 닉네임 입력 필드
                    const Text(
                      '닉네임',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    // 3) 상태 메시지 입력 필드
                    const Text(
                      '상태 메시지',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        onPressed: _isLoading ? null : _onSaveProfile,
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
