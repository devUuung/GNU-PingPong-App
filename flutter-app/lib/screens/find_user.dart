import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'win_lost_select.dart';
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_app/services/user_service.dart';
import 'dart:async';

class FindUserPage extends StatefulWidget {
  const FindUserPage({Key? key}) : super(key: key);

  @override
  _FindUserPageState createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  final UserService _userService = UserService();
  List<dynamic> _matchUsers = [];
  bool _isLoading = false;
  bool _isRequestingMatch = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUsersInfo(context);
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUserInfo(context);

      // 사용자 매칭 상태 확인
      _checkMatchStatus();
    });
  }

  @override
  void dispose() {
    // 매칭 요청 활성화 상태면 취소
    if (_isRequestingMatch) {
      _cancelMatchRequest();
    }
    // 타이머 정리
    _refreshTimer?.cancel();
    super.dispose();
  }

  // 매칭 상태 확인
  Future<void> _checkMatchStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 내 매칭 요청 조회
      final myRequest = await _userService.getMyMatchRequest();

      // 이미 매칭 요청 중인 경우
      if (myRequest != null) {
        setState(() {
          _isRequestingMatch = true;
        });
        // 다른 매칭 요청 사용자 조회
        await _loadMatchRequests();
        // 자동 새로고침 타이머 시작
        _startRefreshTimer();
      }
    } catch (e) {
      print('매칭 상태 확인 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('매칭 상태 확인 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 매칭 요청 시작
  Future<void> _startMatchRequest() async {
    if (_isRequestingMatch) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.createMatchRequest();
      setState(() {
        _isRequestingMatch = true;
      });

      // 다른 매칭 요청 사용자 조회
      await _loadMatchRequests();

      // 자동 새로고침 타이머 시작
      _startRefreshTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('경기 입력 상태가 시작되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('매칭 요청 시작 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('매칭 요청 시작 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 매칭 요청 취소
  Future<void> _cancelMatchRequest() async {
    if (!mounted) return; // 혹은 위젯이 dispose된 상황을 먼저 확인
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _userService.cancelMatchRequest();
      print(success);
      if (success) {
        print("aa");
        if (mounted) {
          setState(() {
            _isRequestingMatch = false;
            _matchUsers = [];
          });
        }
        print("bb");
        // 타이머 취소
        _refreshTimer?.cancel();
        print("cc");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('경기 입력 상태가 취소되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('매칭 요청 취소 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('매칭 요청 취소 중 오류가 발생했습니다.\n서버 관리자에게 문의하세요.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 자동 새로고침 타이머 시작
  void _startRefreshTimer() {
    // 기존 타이머 취소
    _refreshTimer?.cancel();

    // 10초마다 자동 갱신
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isRequestingMatch && mounted) {
        _loadMatchRequests();
      }
    });
  }

  // 매칭 요청 목록 로드
  Future<void> _loadMatchRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await _userService.getAllMatchRequests();
        if (mounted) {
          setState(() {
            // response는 MatchRequestWithUser 객체 리스트이므로, 각 객체의 user 속성을 추출
            _matchUsers = response.map((req) => req.user).toList();
            _isLoading = false;
          });
        }
        return; // 성공하면 함수 종료
      } catch (e) {
        retryCount++;
        print('매칭 요청 목록 로드 중 오류($retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('서버 오류가 발생했습니다.\n서버 관리자에게 "user_id 필드 누락" 문제를 문의하세요.'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '닫기',
                  onPressed: () {},
                ),
              ),
            );
          }
          break;
        } else {
          // 잠시 대기 후 재시도
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  // 수동 새로고침
  Future<void> _handleRefresh() async {
    if (_isRequestingMatch) {
      await _loadMatchRequests();
    }
    return Future.value();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: const Color(0xFFFEF7FF),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRequestingMatch ? '매칭 대기중..' : '경기 입력하기'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 경기 입력 상태 전환 버튼
          IconButton(
            icon: Icon(_isRequestingMatch
                ? Icons.cancel_outlined
                : Icons.sports_tennis),
            onPressed: _isLoading
                ? null
                : (_isRequestingMatch
                    ? _cancelMatchRequest
                    : _startMatchRequest),
            tooltip: _isRequestingMatch ? '경기 입력 상태 취소' : '경기 입력 상태 시작',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Container(
            color: const Color(0xFFFEF7FF),
            child: Column(
              children: [
                // 상태 표시
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('매칭 가능한 사용자 검색 중...'),
                      ],
                    ),
                  ),

                // 경기 입력 상태 안내 메시지
                if (_isRequestingMatch)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '경기 입력 상태가 활성화되었습니다.\n'
                        '화면을 아래로 당겨 새로고침하여 다른 사용자를 찾을 수 있습니다.\n'
                        '게임 상대를 선택하여 경기를 입력해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),

                // 경기 입력 상태 시작 안내
                if (!_isRequestingMatch)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sports_tennis,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '경기 입력을 시작하려면\n오른쪽 상단의 버튼을 눌러주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startMatchRequest,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('경기 입력 시작'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 발견된 사용자가 없을 경우
                if (_matchUsers.isEmpty && _isRequestingMatch)
                  const Expanded(
                    child: Center(
                      child: Text(
                        '현재 경기 입력 중인 다른 사용자가 없습니다.\n'
                        '잠시 후 다시 시도해보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                // 발견된 사용자 목록
                if (_matchUsers.isNotEmpty)
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _matchUsers.length,
                      itemBuilder: (context, index) {
                        final student = _matchUsers[index];
                        final String studentName =
                            student['username'] ?? '이름없음';
                        final int userId = student['user_id'] ?? 0;
                        final String myName =
                            usersProvider.userInfo?.username ?? '';
                        final int myUserId =
                            usersProvider.userInfo?.userId ?? 0;
                        final String? profileImage =
                            student['profile_image_url'];

                        return _buildStudentItem(
                          context,
                          myName,
                          myUserId,
                          studentName,
                          userId,
                          profileImage,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 학생 아이콘, 이름, 탭 시 이벤트 처리
  Widget _buildStudentItem(
    BuildContext context,
    String myName,
    int myUserId,
    String otherName,
    int otherUserId,
    String? profileImageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WinLoseSelect(
                otherName: otherName,
                otherId: otherUserId,
                myName: myName,
                myId: myUserId,
              ),
            ),
          );
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지 또는 기본 아이콘
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_outline,
                        size: 60,
                        color: Colors.black54,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Colors.black54,
                    ),
            ),
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
