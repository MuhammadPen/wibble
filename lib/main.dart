import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/pages/gameplay.dart';
import 'package:wibble/pages/mainmenu.dart';
import 'package:wibble/pages/privateLobby.dart';
import 'package:wibble/types.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
        routes: {
          '/mainmenu': (context) => Mainmenu(),
          '/gameplay': (context) => Gameplay(),
          '/privateLobby': (context) => PrivateLobby(),
        },
      ),
    );
  }
}

class Store extends ChangeNotifier {
  var lobbyData = Lobby(
    id: '',
    rounds: 3,
    wordLength: 5,
    maxAttempts: 6,
    playerCount: 1,
    players: {},
    startTime: DateTime.now(),
    maxPlayers: 2,
    type: LobbyType.oneVOne,
  );
  var user = User(
    id: '',
    username: '',
    rank: Rank.bronze,
    createdAt: DateTime.now(),
  );

  // Subscription management
  StreamSubscription<DocumentSnapshot>? lobbySubscription;
  bool _isMatchmaking = false;

  bool get isMatchmaking => _isMatchmaking;
  set isMatchmaking(bool value) {
    _isMatchmaking = value;
    notifyListeners();
  }

  // Start matchmaking and manage subscription
  Future<void> searchForGame({required LobbyType type}) async {
    _isMatchmaking = true;
    notifyListeners();

    try {
      final lobbyStream = await startMatchmaking(
        type: type,
        playerInfo: LobbyPlayerInfo(
          user: user,
          score: 0,
          round: 0,
          attempts: 0,
        ),
      );

      lobbySubscription = lobbyStream.listen((event) {
        final data = event.data() as Map<String, dynamic>;
        lobbyData = Lobby.fromJson(data);
        notifyListeners();
      });
    } catch (error) {
      notifyListeners();
      rethrow;
    }
  }

  // Cancel the subscription
  void cancelLobbySubscription() {
    lobbySubscription?.cancel();
    lobbySubscription = null;
    _isMatchmaking = false;
    notifyListeners();
  }

  Future<void> resumeMatch() async {
    final lobby = await checkForOnGoingMatch(playerId: user.id);
    if (lobby != null) {
      lobbyData = lobby;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    lobbySubscription?.cancel();
    super.dispose();
  }
}
