import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/pages/gameplay.dart';
import 'package:wibble/pages/mainmenu.dart';
import 'package:wibble/pages/private_lobby.dart';
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
      child: MyAppContent(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  var _isSubscribed = false;

  @override
  Widget build(BuildContext context) {
    final store = context.read<Store>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSubscribed) return;
      final inviteStream = subscribeToInvites(playerId: store.user.id);
      inviteStream.listen((event) {
        final data = event.docs
            .map((doc) => Invite.fromJson(doc.data()))
            .toList();
        store.invites = data;
        setState(() {
          _isSubscribed = true;
        });
      });
    });

    return MaterialApp(
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
  var invites = <Invite>[];

  // Subscription management
  StreamSubscription<DocumentSnapshot>? lobbySubscription;
  StreamSubscription<DocumentSnapshot>? invitesSubscription;
  bool _isMatchmaking = false;

  bool get isMatchmaking => _isMatchmaking;
  set isMatchmaking(bool value) {
    _isMatchmaking = value;
    notifyListeners();
  }

  // Cancel the subscription
  void cancelLobbySubscription() {
    lobbySubscription?.cancel();
    lobbySubscription = null;
    _isMatchmaking = false;
    notifyListeners();
  }

  void cancelInvitesSubscription() {
    invitesSubscription?.cancel();
    invitesSubscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    lobbySubscription?.cancel();
    invitesSubscription?.cancel();
    super.dispose();
  }

  Future<void> resumeMatch() async {
    final lobby = await checkForOnGoingMatch(playerId: user.id);
    if (lobby != null) {
      lobbyData = lobby;
      notifyListeners();
    }
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

  Future<void> createPrivateLobby() async {
    try {
      final lobbyStream = await startPrivateLobby(
        playerInfo: LobbyPlayerInfo(
          user: user,
          score: 0,
          round: 0,
          attempts: 0,
          isAdmin: true,
        ),
      );

      // final lobbyStream = await startPrivateLobbyWithMockUsers(
      //   playerInfo: LobbyPlayerInfo(
      //     user: user,
      //     score: 0,
      //     round: 0,
      //     attempts: 0,
      //     isAdmin: true,
      //   ),
      // );

      lobbySubscription = lobbyStream.listen((event) {
        final data = event.data();
        if (data != null) {
          lobbyData = Lobby.fromJson(data as Map<String, dynamic>);
          notifyListeners();
        }
      });
    } catch (error) {
      notifyListeners();
      rethrow;
    }
  }
}
