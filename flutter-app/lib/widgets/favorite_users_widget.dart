// lib/widgets/favorite_users_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/star_users_info_provider.dart';

class FavoriteUsersWidget extends StatelessWidget {
  const FavoriteUsersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StarUsersInfoProvider>(
      builder: (context, starUsersProvider, child) {
        final starredUsers = starUsersProvider.starUsers;
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
              // 좌측 패딩을 18로 하여 헤더와 일치
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4),
              child: Row(
                children: [
                  // 유저 이름
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // 유저 이름과 승/패 사이 간격 좁게 (4)
                  const SizedBox(width: 12),
                  // 승리/패배 정보
                  Text(
                    '$winCount승 $loseCount패',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 승률
                  Text(
                    '승률 ${winRate.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  // 승률과 게임수 사이 간격 넓게 (12)
                  const SizedBox(width: 12),
                  // 게임수
                  Text(
                    '게임수 ${gameCount}회',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
