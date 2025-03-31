import 'package:flutter/material.dart';
import 'win_lost_select.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class FindUserPage extends StatefulWidget {
  const FindUserPage({super.key});

  @override
  State<FindUserPage> createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  List<dynamic> _matchUsers = [];
  bool _isLoading = false;
  bool _isRequestingMatch = false;
  Timer? _refreshTimer;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkMatchStatus();
  }

  Future<void> _loadUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('userinfo')
          .select('*')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userInfo = response;
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 중 오류: $e');
    }
  }

  @override
  void dispose() {
    if (_isRequestingMatch) {
      _cancelMatchRequest();
    }
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMatchStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final myRequest = await supabase
          .from('match_requests')
          .select('*')
          .eq('user_id', user.id)
          .single();

      if (myRequest != null && mounted) {
        setState(() {
          _isRequestingMatch = true;
        });
        await _loadMatchRequests();
        _startRefreshTimer();
      }
    } catch (e) {
      debugPrint('매칭 상태 확인 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('매칭 상태 확인 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
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

  Future<void> _startMatchRequest() async {
    if (_isRequestingMatch) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('match_requests').insert({
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isRequestingMatch = true;
        });

        await _loadMatchRequests();
        _startRefreshTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('경기 입력 상태가 시작되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('매칭 요청 시작 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('매칭 요청 시작 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
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

  Future<void> _cancelMatchRequest() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('match_requests').delete().eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _isRequestingMatch = false;
          _matchUsers = [];
        });
        _refreshTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('경기 입력 상태가 취소되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('매칭 요청 취소 중 오류: $e');
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

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isRequestingMatch && mounted) {
        _loadMatchRequests();
      }
    });
  }

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
        final user = supabase.auth.currentUser;
        if (user == null) return;

        final response = await supabase
            .from('match_requests')
            .select('*, userinfo(*)')
            .neq('user_id', user.id);

        if (mounted) {
          setState(() {
            _matchUsers = response.map((req) => req['userinfo']).toList();
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        retryCount++;
        debugPrint('매칭 요청 목록 로드 중 오류($retryCount/$maxRetries): $e');

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
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRequestingMatch) {
      await _loadMatchRequests();
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                        final int userId = student['id'] ?? 0;
                        final String myName = _userInfo?['username'] ?? '';
                        final int myUserId = _userInfo?['id'] ?? 0;
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
        if (!mounted) return;
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
