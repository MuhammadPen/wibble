import 'package:flutter/material.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/components/widgets/user_card.dart';
import 'package:wibble/types.dart';

class TitleCard extends StatelessWidget {
  final User user;

  const TitleCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ShadowContainer(
      backgroundColor: Color(0xff2E2E2E),
      width: 370,
      child: Column(
        children: [
          //wibble text
          Container(
            height: 340, // Adjust height as needed
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Text(
                    "W____",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Bungee",
                      fontSize: 58,
                      color: Color(0xffFFC700),
                    ),
                  ),
                ),
                Positioned(
                  top: 62, // 58 - 10 for overlap
                  left: 0,
                  right: 0,
                  child: Text(
                    "_I___",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Bungee",
                      fontSize: 58,
                      color: Color(0xff32CC7A),
                    ),
                  ),
                ),
                Positioned(
                  top: 62 + 62, // 48 + 48
                  left: 0,
                  right: 0,
                  child: Text(
                    "__B__",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Bungee",
                      fontSize: 58,
                      color: Color(0xff0099FF),
                    ),
                  ),
                ),
                Positioned(
                  top: 62 + 62 + 62, // 96 + 48
                  left: 0,
                  right: 0,
                  child: Text(
                    "___L_",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Bungee",
                      fontSize: 58,
                      color: Color(0xffFF7300),
                    ),
                  ),
                ),
                Positioned(
                  top: 62 + 62 + 62 + 62, // 144 + 48
                  left: 0,
                  right: 0,
                  child: Text(
                    "____E",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Bungee",
                      fontSize: 58,
                      color: Color(0xffFF0000),
                    ),
                  ),
                ),
              ],
            ),
          ),
          //user card
          UserCard(user: user),
        ],
      ),
    );
  }
}
