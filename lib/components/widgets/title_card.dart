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
          Column(
            children: [
              Text(
                "W____",
                style: TextStyle(
                  fontFamily: "Bungee",
                  fontSize: 58,
                  color: Color(0xffFFC700),
                ),
              ),
              Text(
                "_I___",
                style: TextStyle(
                  fontFamily: "Bungee",
                  fontSize: 58,
                  color: Color(0xff32CC7A),
                ),
              ),
              Text(
                "__B__",
                style: TextStyle(
                  fontFamily: "Bungee",
                  fontSize: 58,
                  color: Color(0xff0099FF),
                ),
              ),
              Text(
                "___L_",
                style: TextStyle(
                  fontFamily: "Bungee",
                  fontSize: 58,
                  color: Color(0xffFF7300),
                ),
              ),
              Text(
                "____E",
                style: TextStyle(
                  fontFamily: "Bungee",
                  fontSize: 58,
                  color: Color(0xffFF0000),
                ),
              ),
            ],
          ),
          //user card
          UserCard(user: user),
        ],
      ),
    );
  }
}
