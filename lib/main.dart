import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/pages/gameplay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Store(),
      child: MaterialApp(
        title: 'Wibble',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Gameplay(),
      ),
    );
  }
}

class Store extends ChangeNotifier {
  var lobbyData = {
    "players": [],
    "rounds": 3,
    "wordLength": 5,
    "maxAttempts": 6,
  };
}
