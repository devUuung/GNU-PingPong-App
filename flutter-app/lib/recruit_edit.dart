import 'package:flutter/material.dart';

/// 모집 공고 수정 페이지
class RecruitEditPage extends StatefulWidget {
  const RecruitEditPage({Key? key}) : super(key: key);

  @override
  State<RecruitEditPage> createState() => _RecruitEditPageState();
}

class _RecruitEditPageState extends State<RecruitEditPage> {
  // 기존 데이터를 가져와서 초기화할 수도 있음
  final _titleController = TextEditingController(text: "탁구 치실 분~?");
  final _contentController = TextEditingController(text: "동방에서 3시에 칠까요?");
  final _maxPeopleController = TextEditingController(text: "4");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모집 공고 수정'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("제목"),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "예) 탁구 치실 분 구합니다!",
                ),
              ),
              const SizedBox(height: 16),
              const Text("내용"),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "본문 내용을 입력하세요",
                ),
              ),
              const SizedBox(height: 16),
              const Text("최대 인원"),
              TextField(
                controller: _maxPeopleController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "예) 4",
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: 수정 처리 로직 (DB 업데이트 등)
                  print("수정 완료!");
                  Navigator.pop(context); // 이전 화면(Home)으로 복귀
                },
                child: const Text("수정 완료"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
