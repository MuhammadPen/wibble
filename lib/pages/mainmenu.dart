import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wibble/pages/gameplay.dart';

class Mainmenu extends StatelessWidget {
  const Mainmenu({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: TextStyle(fontSize: 16),
      elevation: 0,
    );
    return Scaffold(
      appBar: AppBar(title: Text('Wibble')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text("Play"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Gameplay()),
                );
              },
              style: buttonStyle,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.person),
              label: Text("Private lobby"),
              onPressed: () {},
              style: buttonStyle,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.help),
              label: Text("How to play"),
              onPressed: () {},
              style: buttonStyle,
            ),
            SizedBox(height: 10),
            if (!kIsWeb)
              ElevatedButton.icon(
                icon: Icon(Icons.exit_to_app),
                label: Text("Exit"),
                onPressed: () {
                  exit(0);
                },
                style: buttonStyle,
              ),
          ],
        ),
      ),
    );
  }
}
