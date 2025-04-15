import 'package:flutter/material.dart';
import 'package:gnu_pingpong_app/screens/post_edit.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

/// 게시글 위젯
class Post extends StatefulWidget {
  const Post({super.key});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR');
    _fetchPosts();
  }

  // 모집공고 목록 가져오기
  Future<void> _fetchPosts() async {
    debugPrint("Fetching posts...");
    setState(() {
      _isLoading = true;
    });

    final user = supabase.auth.currentUser;
    _currentUserId = user?.id;
    debugPrint("Current User ID: $_currentUserId");

    try {
      final response = await supabase.from('post').select('*');
      debugPrint("Supabase response: $response");

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        debugPrint("Posts loaded: ${_posts.length}, isLoading: $_isLoading");
      });
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 모집공고 삭제
  Future<void> _deletePost(String postId) async {
    await supabase.from('post').delete().eq('id', postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모집공고가 삭제되었습니다.')),
    );
    _fetchPosts();
  }

  // 모집공고 참가 취소
  Future<void> _leavePost(String postId) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      // 1. 현재 게시글의 users 리스트 가져오기
      final postData = await supabase
          .from('post')
          .select('users')
          .eq('id', postId)
          .single();

      final List<dynamic> currentUsers = List<dynamic>.from(postData['users'] ?? []);
      final originalUsersCount = currentUsers.length;

      // 2. 현재 사용자 ID 제거
      final bool removed = currentUsers.remove(_currentUserId);

      // 3. 업데이트된 users 리스트로 post 테이블 업데이트
      // 실제로 제거되었을 때만 업데이트 시도
      if (removed) {
        await supabase
            .from('post')
            .update({'users': currentUsers})
            .eq('id', postId);
      } else {
         // 사용자가 참가 목록에 없거나 변경사항이 없는 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참가 중이지 않습니다.')),
        );
        return; // 업데이트 불필요
      }

      // 4. DB 업데이트 성공 후 목록 새로고침
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모집공고 참가를 취소했습니다.')),
        );
        _fetchPosts(); // 목록 새로고침
       }
    } catch (e) {
      debugPrint("Error leaving post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참가 취소 중 오류 발생: $e')),
        );
      }
    }
  }

  Future<void> _participatePost(String postId) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      // 1. 현재 게시글의 users 리스트와 max_user 가져오기
      final postData = await supabase
          .from('post')
          .select('users, max_user')  // max_user도 함께 조회
          .eq('id', postId)
          .single();

      final List<dynamic> currentUsers = List<dynamic>.from(postData['users'] ?? []);
      final int participantCount = currentUsers.length;
      final int maxUser = postData['max_user'] as int? ?? 0;
      
      // 최대 인원 체크
      if (participantCount >= maxUser) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 최대 인원에 도달했습니다.')),
          );
        }
        return;
      }

      final originalUsersCount = currentUsers.length;

      // 2. 현재 사용자 ID 추가 (중복 방지)
      if (!currentUsers.contains(_currentUserId)) {
        currentUsers.add(_currentUserId);
      }

      // 3. 업데이트된 users 리스트로 post 테이블 업데이트
      // 변경사항이 있을 때만 업데이트 시도
      if (currentUsers.length > originalUsersCount) {
         await supabase
            .from('post')
            .update({'users': currentUsers})
            .eq('id', postId);
      } else {
        // 이미 참여 중이거나 변경사항이 없는 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 참여 중입니다.')),
        );
        return; // 업데이트 불필요
      }

      // 4. DB 업데이트 성공 후 목록 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모집공고에 참가했습니다.')),
        );
        _fetchPosts(); // 전체 목록 다시 로드
      }

    } catch (e) {
      debugPrint("Error participating post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참가 중 오류 발생: $e')),
        );
      }
    }
  }

  /// 삭제 확인 다이얼로그 표시 후, '예' 선택 시 Post 삭제 처리
  Future<void> _confirmDelete(BuildContext context, String postId) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말로 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // '아니오' → false
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), // '예' → true
              child: const Text('예'),
            ),
          ],
        );
      },
    );

    // 사용자가 '예'를 눌러 result == true라면, 삭제 API 호출
    if (result == true) {
      await _deletePost(postId);
    }
  }

  // 사용자가 참가자인지 확인
  bool _isParticipant(Map<String, dynamic> post) {
    if (_currentUserId == null) return false;

    // post 테이블의 'users' 목록에서 현재 사용자 ID 확인
    final List<dynamic> participants = post['users'] as List<dynamic>? ?? [];
    return participants.contains(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text('모집공고가 없습니다.', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: _posts.map((post) {
        final bool isWriter = post['writer_id'] == _currentUserId;
        final bool isParticipant = _isParticipant(post);

        // game_at null 처리 및 파싱
        DateTime? gameAt;
        String formattedDate = '날짜 정보 없음'; // 기본값
        if (post['created_at'] != null) {
          try {
            gameAt = DateTime.parse(post['created_at'] as String);
            formattedDate = DateFormat('M월 d일 a h시', 'ko_KR').format(gameAt);
          } catch (e) {
            debugPrint("Error parsing created_at: ${post['created_at']} - $e");
            // 파싱 오류 시 기본값 유지
          }
        }

        // 다른 필드 null 처리
        final String title = post['title'] as String? ?? '제목 없음';
        final String gamePlace = post['place'] as String? ?? '장소 정보 없음';
        final int maxUser =
            post['max_user'] as int? ?? 0; // max_user도 null 가능성 고려
        final String content = post['content'] as String? ?? '내용 없음';

        // postId 가져오기
        final String postId = post['id'] as String? ?? '';

        // postId가 유효하지 않으면 위젯을 그리지 않음 (선택적)
        if (postId.isEmpty) return const SizedBox.shrink();

        // 참가자 수 계산
        final List<dynamic> currentParticipants =
            post['users'] as List<dynamic>? ?? [];
        final int participantCount = currentParticipants.length;

        return Container(
          width: 357,
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                    letterSpacing: 0.10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$formattedDate\n$gamePlace\n참가자 수: $participantCount / $maxUser',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 16),

                // 버튼 영역 - 권한에 따라 다른 버튼 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isWriter) ...[
                      // 작성자인 경우 수정/삭제 버튼 표시
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF65558F)),
                            onPressed: () {
                              // 수정 화면으로 이동 (PostEditPage -> RecruitEditPage)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RecruitEditPage(postId: postId),
                                ),
                              ).then((_) => _fetchPosts()); // 돌아왔을 때 목록 새로고침
                            },
                          ),
                          const Text('수정'),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color(0xFF65558F)),
                            onPressed: () => _confirmDelete(context, postId),
                          ),
                          const Text('삭제'),
                        ],
                      ),
                    ] else if (isParticipant) ...[
                      // 참가자인 경우 나가기 버튼 표시
                      ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('나가기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _leavePost(postId),
                      ),
                    ] else ...[
                      // 참가자가 아닌 경우 참여하기 버튼 표시
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('참여하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF65558F),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _participatePost(postId),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
