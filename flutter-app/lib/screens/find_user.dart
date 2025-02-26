import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'win_lost_select.dart';
import 'package:flutter_app/providers/users_info_provider.dart';

class FindUserPage extends StatefulWidget {
  const FindUserPage({Key? key}) : super(key: key);

  @override
  _FindUserPageState createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUsersInfo(context);
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUserInfo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersInfoProvider>(context);

    // 로딩 중이면 로딩 인디케이터 표시
    if (usersProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('주변 사람 찾는중..'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFFFEF7FF),
        ),
        backgroundColor: const Color(0xFFFEF7FF),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<dynamic> students = usersProvider.users ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 사람 찾는중..'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFEF7FF),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final String studentName = student['username'] ?? '이름없음';
              final int userId = student['user_id'] ?? 0;
              final String myName = usersProvider.userInfo?['username'] ?? '';
              final int myUserId = usersProvider.userInfo?['user_id'] ?? 0;
              return _buildStudentItem(
                  context, myName, myUserId, studentName, userId);
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFEF7FF),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: const Text(
          '블루투스가 켜져있는지 확인해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1D1B20),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 학생 아이콘, 이름, 탭 시 이벤트 처리
  Widget _buildStudentItem(BuildContext context, String myName, int myUserId,
      String otherName, int otherUserId) {
    return GestureDetector(
      onTap: () {
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WinLoseSelect(
                otherName: otherName,
                otherUserId: otherUserId,
                myName: myName,
                myUserId: myUserId,
              ),
            ),
          );
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 60,
            color: Colors.black54,
          ),
          const SizedBox(height: 8),
          Text(
            otherName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
