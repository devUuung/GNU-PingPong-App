import 'package:flutter/material.dart';
import 'package:flutter_app/screens/post_edit.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

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
    setState(() {
      _isLoading = true;
    });

    // 현재 사용자 ID 가져오기
    final user = supabase.auth.currentUser;
    _currentUserId = user?.id;

    // 모집공고 목록 가져오기
    final posts = await supabase.from('post').select('*');
    setState(() {
      _posts = List<Map<String, dynamic>>.from(posts);
      _isLoading = false;
    });
  }

  // 모집공고 삭제
  Future<void> _deletePost(int postId) async {
    await supabase.from('posts').delete().eq('post_id', postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모집공고가 삭제되었습니다.')),
    );
    _fetchPosts(); // 목록 새로고침
  }

  // 모집공고 참가 취소
  Future<void> _leavePost(int postId) async {
    await supabase.from('post_participant').delete().eq('post_id', postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모집공고 참가를 취소했습니다.')),
    );
    _fetchPosts(); // 목록 새로고침
  }

  Future<void> _participatePost(int postId) async {
    await supabase.from('post_participant').insert({
      'post_id': postId,
      'user_id': _currentUserId,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모집공고에 참가했습니다.')),
    );
    _fetchPosts(); // 목록 새로고침
  }

  /// 삭제 확인 다이얼로그 표시 후, '예' 선택 시 Post 삭제 처리
  Future<void> _confirmDelete(BuildContext context, int postId) async {
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

    // 참가자 목록을 가져오기 위해 API 호출이 필요할 수 있음
    // 현재는 간단하게 작성자인 경우만 참가자로 간주
    return post['writer_id'] == _currentUserId;
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
        final DateTime gameAt = DateTime.parse(post['game_at']);
        final String formattedDate =
            DateFormat('M월 d일 a h시', 'ko_KR').format(gameAt);

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
                  '${post['title']}',
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
                  '$formattedDate\n${post['game_place']}\n참가자 수: ? / ${post['max_user']}',
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
                  '${post['content']}',
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
                              // 수정 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RecruitEditPage(postId: post['post_id']),
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
                            onPressed: () =>
                                _confirmDelete(context, post['post_id']),
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
                        onPressed: () => _leavePost(post['post_id']),
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
                        onPressed: () => _participatePost(post['post_id']),
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
