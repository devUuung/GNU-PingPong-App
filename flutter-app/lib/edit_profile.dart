import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/bottom_bar.dart';
import 'dart:io';
import 'package:flutter_app/dialog.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // 초기값을 별도 변수로 관리하여 변경 여부 비교
  final String _initialNickname = '김학생';
  final String _initialStatusMsg = '안녕하십니까. 뉴비입니다 잘부탁드립니다.';

  late TextEditingController _nicknameController;
  late TextEditingController _statusMessageController;

  // 갤러리에서 선택된 프로필 이미지 파일
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: _initialNickname);
    _statusMessageController = TextEditingController(text: _initialStatusMsg);
  }

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

  /// “저장하기” 버튼을 누르면 변경된 정보만 체크해서 API에 수정 요청을 보냅니다.
  Future<void> _onSaveProfile() async {
    final newNickname = _nicknameController.text.trim();
    final newStatusMsg = _statusMessageController.text.trim();

    bool changed = false;
    Map<String, String> updatedFields = {};

    if (newNickname != _initialNickname) {
      updatedFields["nickname"] = newNickname;
      changed = true;
    }
    if (newStatusMsg != _initialStatusMsg) {
      updatedFields["status_message"] = newStatusMsg;
      changed = true;
    }
    if (_profileImageFile != null) {
      // 이미지가 선택되었으면 변경된 것으로 간주
      changed = true;
    }

    if (!changed) {
      showErrorDialog(context, '변경된 정보가 없습니다.');
      return;
    }

    try {
      // JWT 토큰에서 user_id 추출
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        showErrorDialog(context, '로그인이 필요합니다.');
        return;
      }
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['user_id']; // jwt에 user_id가 있다고 가정

      // PATCH 요청을 보낼 URL 구성
      final url = '${ApiConfig.userinfo}/$userId';
      final uri = Uri.parse(url);

      // Authorization 헤더에 토큰 포함
      Map<String, String> headers = {
        "Authorization": "Bearer $token",
      };

      if (_profileImageFile != null) {
        // 프로필 이미지와 텍스트가 함께 변경된 경우 Multipart 요청 사용
        var request = http.MultipartRequest("PATCH", uri);
        request.headers.addAll(headers);
        updatedFields.forEach((key, value) {
          request.fields[key] = value;
        });
        request.files.add(await http.MultipartFile.fromPath(
            "profile_image", _profileImageFile!.path));
        var response = await request.send();
        if (response.statusCode == 200) {
          Navigator.pop(context);
        } else {
          showErrorDialog(context, '프로필 업데이트 실패: ${response.statusCode}');
        }
      } else {
        // 텍스트만 변경된 경우 JSON PATCH 요청
        headers["Content-Type"] = "application/json";
        var response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(updatedFields),
        );
        if (response.statusCode == 200) {
          Navigator.pop(context);
        } else {
          showErrorDialog(context, '프로필 업데이트 실패: ${response.statusCode}');
        }
      }
    } catch (e) {
      showErrorDialog(context, '프로필 업데이트 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        currentPage: "editProfile",
      ),
      backgroundColor: const Color(0xFFFEF7FF),
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
              // 1) 프로필 이미지 영역
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageFile == null
                          ? const NetworkImage('https://picsum.photos/200')
                          : FileImage(_profileImageFile!) as ImageProvider,
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
              // 2) 닉네임 입력 필드
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
              // 3) 상태 메시지 입력 필드
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
