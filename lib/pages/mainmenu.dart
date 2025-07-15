import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/main.dart';
import 'package:wibble/pages/gameplay.dart';

class Mainmenu extends StatefulWidget {
  const Mainmenu({super.key});

  @override
  State<Mainmenu> createState() => _MainmenuState();
}

class _MainmenuState extends State<Mainmenu> {
  String? _previousLobbyDataString;
  bool _hasNavigated = false; // Add flag to prevent multiple navigations

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = Provider.of<Store>(context);
    final lobbyData = store.lobbyData;

    if (lobbyData.playerCount > 1 && !_hasNavigated) {
      _hasNavigated = true; // Set flag to prevent future navigations
      // Defer state changes until after the current build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        store.isMatchmaking = false;
        Navigator.pushNamed(context, '/gameplay');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Store>(context);
    final user = store.user;
    final isMatchmaking = store.isMatchmaking;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.resumeMatch();
    });

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
        child: isMatchmaking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Finding opponent...', style: TextStyle(fontSize: 18)),
                ],
              )
            : Column(
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
                    label: Text("1v1"),
                    onPressed: () async {
                      await store.startMatchmaking();
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
