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

class _FindUserPageState extends State<FindUserPage> with WidgetsBindingObserver {
  List<dynamic> _matchUsers = [];
  bool _isLoading = true;
  bool _isRequestingMatch = false;
  Timer? _refreshTimer;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMatchingProcess();
  }

  Future<void> _initializeMatchingProcess() async {
    await _loadUserInfo();
    await _checkMatchStatus();
    
    if (!_isRequestingMatch) {
      await _startMatchRequest();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached) {
      _cancelMatchRequest();
    }
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
    WidgetsBinding.instance.removeObserver(this);
    if (_isRequestingMatch) {
      _cancelMatchRequest();
    }
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMatchStatus() async {
    if (!mounted) return;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final myMatches = await supabase
          .from('match')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (myMatches.isNotEmpty && mounted) {
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

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('사용자가 로그인되어 있지 않습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요합니다. 다시 로그인해 주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 세션 확인
      final session = supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        debugPrint('세션이 만료되었습니다. 재로그인이 필요합니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 세션이 만료되었습니다. 다시 로그인해 주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      debugPrint('Supabase 인증 상태: ${user.id}');
      
      // 직접 RPC 함수를 통해 데이터 삽입 시도
      await supabase.rpc('insert_match', params: {
        'user_uuid': user.id,
      });

      if (mounted) {
        setState(() {
          _isRequestingMatch = true;
        });

        await _loadMatchRequests();
        _startRefreshTimer();
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
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('사용자가 로그인되어 있지 않습니다.');
        return;
      }

      // 세션 확인
      final session = supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        debugPrint('세션이 만료되었습니다.');
        return;
      }

      debugPrint('매칭 요청 취소 시도: ${user.id}');
      
      // 직접 RPC 함수를 통해 데이터 삭제 시도
      await supabase.rpc('delete_match', params: {
        'user_uuid': user.id,
      });

      if (mounted) {
        setState(() {
          _isRequestingMatch = false;
          _matchUsers = [];
        });
        _refreshTimer?.cancel();
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
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
            .from('match')
            .select('*, userinfo(*)')
            .neq('user_id', user.id);

        debugPrint('Fetched match users data: $response');

        if (mounted) {
          setState(() {
            _matchUsers = response.map((req) {
              final userInfo = req['userinfo'];
              debugPrint('Processing userinfo: $userInfo');
              return userInfo;
            }).toList();
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
    await _loadMatchRequests();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cancelMatchRequest();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('경기 입력하기'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFFFEF7FF),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _cancelMatchRequest();
              Navigator.of(context).pop();
            },
          ),
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
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '화면을 아래로 당겨 새로고침하여 다른 사용자를 찾을 수 있습니다.\n'
                        '게임 상대를 선택하여 경기를 입력해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  if (_matchUsers.isEmpty && !_isLoading)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '현재 경기 입력 중인 다른 사용자가 없습니다.\n'
                          '화면을 아래로 당겨 새로고침 해보세요.',
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
                          final String userId = student['id'] ?? '';
                          final String myName = _userInfo?['username'] ?? '';
                          final String myUserId = _userInfo?['id'] ?? '';

                          return _buildStudentItem(
                            context,
                            myName,
                            myUserId,
                            studentName,
                            userId,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentItem(
    BuildContext context,
    String myName,
    String myUserId,
    String otherName,
    String otherUserId,
  ) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
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
        ).then((_) {
          _checkMatchStatus();
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
              child: (otherUserId.isNotEmpty)
                  ? FutureBuilder<String>(
                      future: () {
                        final imagePath = 'public/$otherUserId.png';
                        debugPrint("프로필 이미지 경로: $imagePath");
                        return supabase.storage
                            .from('avatars')
                            .createSignedUrl(imagePath, 60);
                      }(),
                      builder: (context, snapshot) {
                        debugPrint(
                            "FutureBuilder 상태: ${snapshot.connectionState}, 데이터있음: ${snapshot.hasData}, 에러있음: ${snapshot.hasError}");
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          debugPrint("이미지 URL 에러 또는 없음: ${snapshot.error}");
                          return const Icon(
                            Icons.person_outline,
                            size: 60,
                            color: Colors.black54,
                          );
                        }
                        final imageUrl = snapshot.data!;
                        debugPrint("이미지 URL: $imageUrl");
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("이미지 로드 에러: $error");
                            return const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.black54,
                            );
                          },
                        );
                      },
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
