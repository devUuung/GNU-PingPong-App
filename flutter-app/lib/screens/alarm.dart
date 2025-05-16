import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 알림 화면
class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  /// Supabase에서 현재 사용자의 알림 목록을 가져옴
  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 현재 로그인된 사용자 정보 가져오기
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // fcm_notifications 테이블에서 현재 사용자의 알림만 가져오기
      final response = await Supabase.instance.client
          .from('fcm_notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('알림 가져오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 알림을 읽음 상태로 표시
  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('fcm_notifications')
          .update({
            'completed_at': DateTime.now().toIso8601String(), 
            'status': 'read'
          })
          .eq('id', notificationId);
      
      // 상태 업데이트
      await _fetchNotifications();
    } catch (e) {
      print('알림 읽음 표시 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF7FF),
        title: const Text(
          '알림',
          style: TextStyle(color: Color(0xFF1D1B20)),
        ),
        centerTitle: true,
        elevation: 2.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1D1B20)),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFEF7FF),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('알림이 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      // status 필드로 읽음 여부 확인 (sent: 안읽음, read: 읽음)
                      final isRead = notification['status'] == 'read';
                      final createdAt = DateTime.parse(notification['created_at']);
                      final formattedDate = '${createdAt.year}/${createdAt.month}/${createdAt.day} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
                      
                      return InkWell(
                        onTap: () {
                          // 클릭 시 무조건 읽음 상태로 변경
                          if (notification['status'] != 'read') {
                            _markAsRead(notification['id']);
                          }
                          
                          // post_id가 있으면 해당 게시물로 이동 가능
                          if (notification['post_id'] != null) {
                            // TODO: 게시물 상세 페이지로 이동
                            // Navigator.push(context, MaterialPageRoute(
                            //   builder: (context) => PostDetailPage(postId: notification['post_id'])
                            // ));
                          }
                        },
                        child: Container(
                          color: isRead ? Colors.white : const Color(0xFFFFEDF5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 알림 제목
                              Text(
                                notification['title'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF1D1B20),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // 알림 본문
                              Text(
                                '${notification['body'] ?? ''}\n$formattedDate',
                                style: const TextStyle(
                                  color: Color(0xFF49454F),
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.43,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
