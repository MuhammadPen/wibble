import 'package:flutter/material.dart';
import 'package:wibble/components/ui/clock.dart';
import 'package:wibble/types.dart';

class GameStatus extends StatelessWidget {
  final int remainingSeconds;
  final String currentUserId;
  final Map<String, LobbyPlayerInfo> players;

  const GameStatus({
    super.key,
    required this.remainingSeconds,
    required this.currentUserId,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          ClockWidget(
            remainingSeconds: remainingSeconds,
            totalSeconds: remainingSeconds,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              children: players.entries.map((entry) {
                final playerId = entry.key;
                final playerInfo = entry.value;
                final isCurrentUser = playerId == currentUserId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCurrentUser ? "Your score" : playerInfo.user.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isCurrentUser
                              ? Colors.blue[700]
                              : Colors.black,
                        ),
                      ),
                      Text(
                        '${playerInfo.score}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isCurrentUser
                              ? Colors.blue[700]
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
