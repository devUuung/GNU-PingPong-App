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
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/users_info_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // 초기값을 별도 변수로 관리하여 변경 여부 비교
  String _initialNickname = '';
  String _initialStatusMsg = '';
  String _profileImageUrl = '';

  // 기본 프로필 이미지 URL
  final String _defaultProfileImageUrl =
      '${ApiConfig.baseUrl}/static/default_profile.png';

  late TextEditingController _nicknameController;
  late TextEditingController _statusMessageController;

  // 갤러리에서 선택된 프로필 이미지 파일
  File? _profileImageFile;

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
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 정보 가져오기
      await Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUserInfo(context);
      final userInfo =
          Provider.of<UsersInfoProvider>(context, listen: false).userInfo;

      if (userInfo != null) {
        setState(() {
          _initialNickname = userInfo.username ?? '';
          _initialStatusMsg = userInfo.statusMessage ?? '';
          _profileImageUrl =
              userInfo.profileImageUrl ?? _defaultProfileImageUrl;

          // 컨트롤러에 초기값 설정
          _nicknameController.text = _initialNickname;
          _statusMessageController.text = _initialStatusMsg;
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 오류: $e');
      showErrorDialog(context, '사용자 정보를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      showErrorDialog(context, '이미지를 선택하는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _onSaveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final newNickname = _nicknameController.text.trim();
    final newStatusMsg = _statusMessageController.text.trim();

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
    if (_profileImageFile != null) {
      // 이미지가 선택되었으면 변경된 것으로 간주
      changed = true;
    }

    if (!changed) {
      setState(() {
        _isLoading = false;
      });
      showErrorDialog(context, '변경된 정보가 없습니다.');
      return;
    }

    try {
      // Secure Storage에서 토큰 읽기
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        showErrorDialog(context, '로그인이 필요합니다.');
        return;
      }

      // JWT 토큰을 API를 통해 유효성 검사 및 user_id 반환 받기
      final validateUrl = ApiConfig.validateToken;
      final validateResponse = await http.post(
        Uri.parse(validateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (validateResponse.statusCode != 200) {
        showErrorDialog(context, '토큰 검증에 실패했습니다.');
        return;
      }

      final validateData = jsonDecode(validateResponse.body);
      if (validateData['valid'] != true) {
        showErrorDialog(context, '유효하지 않은 토큰입니다.');
        return;
      }
      final userId = validateData['user_id'];

      // PUT 요청을 보낼 URL 구성 (userinfo/{user_id})
      final url = '${ApiConfig.userinfo}/$userId';
      final uri = Uri.parse(url);

      // Authorization 헤더 설정
      Map<String, String> headers = {
        "Authorization": "Bearer $token",
      };

      // 항상 MultipartRequest 사용하되, 메서드를 PUT으로 변경
      var request = http.MultipartRequest("PUT", uri);
      request.headers.addAll(headers);
      updatedFields.forEach((key, value) {
        request.fields[key] = value;
      });
      if (_profileImageFile != null) {
        // 파일 파라미터 이름을 "file"로 변경 (FastAPI에서 받는 이름)
        request.files.add(
            await http.MultipartFile.fromPath("file", _profileImageFile!.path));
      }
      var response = await request.send();

      if (response.statusCode == 200) {
        // 응답 데이터 읽기
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);

        if (jsonData['success'] == true) {
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 성공적으로 업데이트되었습니다.'),
              backgroundColor: Color(0xFF65558F),
            ),
          );
          // 결과 값을 전달하지 않고 단순히 이전 화면으로 돌아갑니다
          Navigator.pop(context);
        } else {
          showErrorDialog(
              context, '프로필 업데이트 실패: ${jsonData['message'] ?? '알 수 없는 오류'}');
        }
      } else {
        showErrorDialog(context, '프로필 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog(context, '프로필 업데이트 중 오류 발생: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                              child: _profileImageFile != null
                                  ? Image.file(
                                      _profileImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _profileImageUrl,
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
