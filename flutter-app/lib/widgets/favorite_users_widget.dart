// lib/widgets/favorite_users_widget.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class FavoriteUsersWidget extends StatefulWidget {
  const FavoriteUsersWidget({super.key});

  @override
  State<FavoriteUsersWidget> createState() => _FavoriteUsersWidgetState();
}

class _FavoriteUsersWidgetState extends State<FavoriteUsersWidget> {
  List<Map<String, dynamic>> starredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadStarredUsers();
  }

  Future<void> _loadStarredUsers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final starUsers = await supabase
          .from('userinfo')
          .select('star_users')
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          starredUsers = List<Map<String, dynamic>>.from(starUsers);
        });
      }
    } catch (e) {
      debugPrint('Error loading starred users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (starredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
        child: Text(
          '즐겨찾기된 유저가 없습니다.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: starredUsers.length,
      itemBuilder: (context, index) {
        final user = starredUsers[index];
        final String name = user['username'] ?? '이름없음';
        final int winCount = user['win_count'] ?? 0;
        final int loseCount = user['lose_count'] ?? 0;
        final int gameCount = user['game_count'] ?? 0;
        double winRate = 0;
        if (gameCount > 0) {
          winRate = (winCount / gameCount) * 100;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$winCount승 $loseCount패',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '승률 ${winRate.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '게임수 $gameCount회',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
