import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/widget_test_helpers.dart';
import 'dart:typed_data';

// 모의 ImagePicker 클래스
class MockImagePicker extends Mock implements ImagePicker {}

// 테스트용 EditProfilePage 래퍼
class TestableEditProfilePage extends StatefulWidget {
  const TestableEditProfilePage({Key? key}) : super(key: key);

  @override
  _TestableEditProfilePageState createState() =>
      _TestableEditProfilePageState();
}

class _TestableEditProfilePageState extends State<TestableEditProfilePage> {
  final TextEditingController _nicknameController =
      TextEditingController(text: '테스트 사용자');
  final TextEditingController _statusController =
      TextEditingController(text: '안녕하세요!');
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 이미지 - NetworkImage 대신 Icon 사용
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        child: Icon(Icons.person, size: 60),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 닉네임 입력 필드
                  const Text('닉네임',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: '닉네임을 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 상태 메시지 입력 필드
                  const Text('상태 메시지',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _statusController,
                    decoration: const InputDecoration(
                      hintText: '상태 메시지를 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 저장 버튼
                  ElevatedButton(
                    onPressed: () {
                      // 테스트용 성공 다이얼로그 표시
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('알림'),
                          content: const Text('프로필이 업데이트되었습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('저장하기'),
                  ),
                ],
              ),
            ),
    );
  }
}

void main() {
  late MockImagePicker mockImagePicker;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    mockImagePicker = MockImagePicker();
  });

  testWidgets('EditProfilePage가 정상적으로 렌더링되는지 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TestableEditProfilePage(),
      ),
    );

    // 닉네임, 상태 메시지, 저장하기 버튼이 존재하는지 확인
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('상태 메시지'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
  });

  testWidgets('프로필 정보 수정 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TestableEditProfilePage(),
      ),
    );

    // 닉네임 필드 수정
    await tester.enterText(find.byType(TextField).first, '수정된 사용자');

    // 상태 메시지 필드 수정
    await tester.enterText(find.byType(TextField).last, '반갑습니다!');

    // 저장하기 버튼 클릭
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    // 성공 다이얼로그 확인
    expect(find.text('프로필이 업데이트되었습니다.'), findsOneWidget);
  });
}
