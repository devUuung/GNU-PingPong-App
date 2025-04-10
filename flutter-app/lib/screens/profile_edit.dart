import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gnu_pingpong_app/widgets/app_bar.dart';
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
  String _userId = ''; // 사용자 ID 저장

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
      _userId = user.id; // 사용자 ID 저장

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
    Map<String, dynamic> updatedFields =
        {}; // String -> dynamic으로 변경 (upsert 때문)

    // 서버에서는 username으로 업데이트하므로 key 변경
    if (newNickname != _initialNickname) {
      updatedFields["username"] = newNickname;
      changed = true;
    }
    if (newStatusMsg != _initialStatusMsg) {
      updatedFields["status"] = newStatusMsg;
      changed = true;
    }

    String? uploadedFilePath; // 업로드된 파일 경로 저장 변수

    // 이미지 변경이 있을 경우 Storage에 업로드/업데이트
    if (_avatarImageFile != null) {
      try {
        final imagePath = 'public/${user.id}.png';
        final imageFile = File(_avatarImageFile!.path);
        final bytes = await _avatarImageFile!.readAsBytes();
        final fileExt = _avatarImageFile!.path.split('.').last.toLowerCase();
        final fileName = '${user.id}.$fileExt'; // 확장자 포함 파일명
        final filePath = 'public/$fileName'; // 최종 스토리지 경로

        // Storage에 파일 업로드 또는 업데이트 (upsert: true 사용)
        await supabase.storage.from('avatars').uploadBinary(
              filePath,
              kIsWeb ? bytes : imageFile.readAsBytesSync(), // 웹/모바일 분기
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true, // 파일이 있으면 덮어쓰기
                contentType: 'image/$fileExt', // Content-Type 설정
              ),
            );
        uploadedFilePath = filePath; // 성공 시 경로 저장
        debugPrint("Image uploaded/updated to: $uploadedFilePath");
        changed = true; // 이미지 변경됨
      } catch (e) {
        debugPrint('Storage 업로드 오류: $e');
        if (!mounted) return;
        showErrorDialog(context, '이미지 업로드 중 오류 발생: $e');
        setState(() => _isLoading = false);
        return; // 오류 시 중단
      }
    }

    // 변경 사항이 있으면 userinfo 테이블 업데이트
    if (changed) {
      // 닉네임 업데이트
      if (updatedFields.containsKey("username")) {
        await supabase
            .from('userinfo')
            .update({'username': updatedFields["username"]}).eq('id', user.id);
      }
      // 상태메시지 업데이트
      if (updatedFields.containsKey("status")) {
        await supabase
            .from('userinfo')
            .update({'status': updatedFields["status"]}).eq('id', user.id);
      }

      // 이미지 경로가 업데이트 되었으면 avatar_url 업데이트 (옵션)
      // 만약 user_list 등 다른 곳에서 avatar_url을 계속 사용한다면 여기서 업데이트
      if (uploadedFilePath != null) {
        await supabase
            .from('userinfo')
            .update({'avatar_url': uploadedFilePath}).eq('id', user.id);
        debugPrint("Updated avatar_url in userinfo: $uploadedFilePath");
      }
    } else {
      // 변경사항 없음 처리
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('변경된 정보가 없습니다.')),
      );
      return;
    }

    // 모든 업데이트 성공 후 처리
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 수정되었습니다.')),
    );
    Navigator.pop(context, true); // 변경되었음을 알리기 위해 true 반환 가능
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "editProfile",
        showNotificationIcon: false,
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
                                  : (_userId.isNotEmpty)
                                      ? FutureBuilder<String>(
                                          future: () {
                                            final imagePath =
                                                'public/$_userId.png';
                                            debugPrint(
                                                "EditProfile trying path: $imagePath");
                                            // createSignedUrl 사용 시 파일 존재 여부 확인 어려움 -> getPublicUrl 사용 고려 또는 오류 처리 강화
                                            try {
                                              // getPublicUrl은 파일이 없어도 오류를 발생시키지 않을 수 있음.
                                              // createSignedUrl은 파일 없으면 오류 발생시킴. 여기서는 오류 처리가 용이한 createSignedUrl 유지.
                                              return supabase.storage
                                                  .from('avatars')
                                                  .createSignedUrl(
                                                      imagePath, 60);
                                            } catch (e) {
                                              debugPrint(
                                                  "Error creating signed URL: $e");
                                              return Future.value(
                                                  ''); // 오류 시 빈 문자열 반환
                                            }
                                          }(),
                                          builder: (context, snapshot) {
                                            debugPrint(
                                                "EditProfile FutureBuilder state: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, HasError: ${snapshot.hasError}");
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2));
                                            }
                                            // 에러가 있거나, 데이터가 없거나, 빈 URL이면 기본 아이콘 표시
                                            if (snapshot.hasError ||
                                                !snapshot.hasData ||
                                                snapshot.data!.isEmpty) {
                                              debugPrint(
                                                  "EditProfile FutureBuilder Error or No Data: ${snapshot.error}");
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.person,
                                                    size: 60,
                                                    color: Colors.grey),
                                              );
                                            }
                                            final imageUrl = snapshot.data!;
                                            debugPrint(
                                                "EditProfile Image URL: $imageUrl");
                                            return Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
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
                                                        strokeWidth: 2));
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                debugPrint(
                                                    "Error loading existing profile image: $error");
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Colors.grey),
                                                );
                                              },
                                            );
                                          },
                                        )
                                      // _userId도 없는 경우 (이론상으론 거의 없음)
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.person,
                                              size: 60, color: Colors.grey),
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
