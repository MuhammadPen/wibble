import 'package:flutter/material.dart';
import 'package:wibble/components/clock.dart';
import 'package:wibble/types.dart';

class GameStatus extends StatelessWidget {
  final int remainingSeconds;
  final User user;
  final int playerScore;
  final LobbyPlayerInfo? opponent;
  const GameStatus({
    super.key,
    required this.remainingSeconds,
    required this.user,
    required this.playerScore,
    required this.opponent,
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your score",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$playerScore',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opponent?.user.username ?? 'Opponent',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${opponent?.score ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
