import 'package:flutter/material.dart';
import 'package:wibble/components/ui/clock.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/styles/text.dart';
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
    return SizedBox(
      width: 370,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadowContainer(
            backgroundColor: Color(0xffF2EEDB),
            width: 90,
            height: 90,
            padding: 0,
            child: ClockWidget(remainingSeconds: remainingSeconds, size: 100),
          ),
          SizedBox(width: 15),
          Expanded(
            child: ShadowContainer(
              backgroundColor: Color(0xffF2EEDB),
              // width: 100,
              // height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: players.entries
                      .toList()
                      .where((entry) => entry.key == currentUserId)
                      .followedBy(
                        players.entries.toList().where(
                          (entry) => entry.key != currentUserId,
                        ),
                      )
                      .map((entry) {
                        final playerId = entry.key;
                        final playerInfo = entry.value;
                        final isCurrentUser = playerId == currentUserId;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCurrentUser
                                  ? "Your score"
                                  : playerInfo.user.username,
                              style: textStyle.copyWith(
                                fontSize: 22,
                                color: isCurrentUser
                                    ? Colors.blue[700]
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              '${playerInfo.score}',
                              style: textStyle.copyWith(
                                fontSize: 22,
                                color: isCurrentUser
                                    ? Colors.blue[700]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
