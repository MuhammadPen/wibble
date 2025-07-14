import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/pages/gameplay.dart';
import 'package:wibble/pages/mainmenu.dart';
import 'package:wibble/types.dart';
import 'firebase/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
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
        home: Mainmenu(),
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
  var user = User(
    id: 'new',
    username: 'bing bong',
    rank: Rank.bronze,
    createdAt: DateTime.now(),
  );
}
