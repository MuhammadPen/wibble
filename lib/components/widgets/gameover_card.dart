import 'package:flutter/material.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/styles/text.dart';
import 'package:wibble/types.dart';

class GameoverCard extends StatelessWidget {
  final Lobby lobby;
  final User user;
  final VoidCallback onClose;

  const GameoverCard({
    super.key,
    required this.lobby,
    required this.user,
    required this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required Lobby lobby,
    required User user,
    required VoidCallback onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameoverCard(lobby: lobby, user: user, onClose: onClose);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = lobby.players.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: ShadowContainer(
        width: 370,
        height: 500,
        backgroundColor: Color(0xffF2EEDB),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Game over', style: textStyle.copyWith(fontSize: 38)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...sortedPlayers.map((player) {
                      final playerName = player.user.username.length > 15
                          ? '${player.user.username.substring(0, 15)}...'
                          : player.user.username;

                      // player is winner if they are the first in the list
                      final isWinner = sortedPlayers.first == player;
                      final isCurrentUser = player.user.id == user.id;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                playerName,
                                style: textStyle.copyWith(
                                  fontSize: isWinner ? 28 : 24,
                                  color: isWinner
                                      ? Color.fromARGB(255, 234, 183, 0)
                                      : isCurrentUser
                                      ? Color(0xff0099FF)
                                      : Colors.black,
                                ),
                              ),
                              if (isWinner)
                                Icon(
                                  Icons.emoji_events,
                                  color: Color(0xffFFC700),
                                ),
                            ],
                          ),
                          Text(
                            player.score.toString(),
                            style: textStyle.copyWith(fontSize: 24),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            CustomButton(
              onPressed: onClose,
              text: 'Back to Menu',
              fontSize: 36,
              fontColor: Colors.white,
              backgroundColor: Color(0xff0099FF),
            ),
          ],
        ),
      ),
    );
  }
}
