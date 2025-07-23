import 'package:flutter/material.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/styles/text.dart';
import 'package:wibble/types.dart';

class LobbyStatus extends StatelessWidget {
  final Lobby lobby;
  final String? currentUserId;

  const LobbyStatus({super.key, required this.lobby, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return ShadowContainer(
      backgroundColor: Color(0xffF2EEDB),
      width: 370,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lobby info
          Text(
            'Players (${lobby.playerCount})',
            style: textStyle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 10),

          // Players list with maximum height and scrolling
          Container(
            constraints: const BoxConstraints(
              maxHeight: 250, // Maximum height before scrolling
            ),
            child: SingleChildScrollView(
              child: Column(
                children: lobby.players.entries.map((entry) {
                  final playerId = entry.key;
                  final playerInfo = entry.value;
                  final isCurrentUser = playerId == currentUserId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // User indicator
                              if (isCurrentUser)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Color(0xff10A958),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // Username
                              Expanded(
                                child: Text(
                                  isCurrentUser
                                      ? "You (${playerInfo.user.username})"
                                      : playerInfo.user.username,
                                  style: textStyle.copyWith(fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // // Rank badge
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 8,
                        //     vertical: 2,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: _getRankColor(playerInfo.user.rank),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Text(
                        //     _getRankDisplayName(playerInfo.user.rank),
                        //     style: const TextStyle(
                        //       fontSize: 12,
                        //       fontWeight: FontWeight.w600,
                        //       color: Colors.white,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Color _getRankColor(Rank rank) {
  //   switch (rank) {
  //     case Rank.bronze:
  //       return Colors.brown[600]!;
  //     case Rank.silver:
  //       return Colors.grey[600]!;
  //     case Rank.gold:
  //       return Colors.amber[600]!;
  //     case Rank.platinum:
  //       return Colors.cyan[600]!;
  //     case Rank.diamond:
  //       return Colors.lightBlue[600]!;
  //     case Rank.master:
  //       return Colors.purple[600]!;
  //     case Rank.grandmaster:
  //       return Colors.red[600]!;
  //   }
  // }

  // String _getRankDisplayName(Rank rank) {
  //   switch (rank) {
  //     case Rank.bronze:
  //       return 'Bronze';
  //     case Rank.silver:
  //       return 'Silver';
  //     case Rank.gold:
  //       return 'Gold';
  //     case Rank.platinum:
  //       return 'Platinum';
  //     case Rank.diamond:
  //       return 'Diamond';
  //     case Rank.master:
  //       return 'Master';
  //     case Rank.grandmaster:
  //       return 'GM';
  //   }
  // }
}
