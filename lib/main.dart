import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wibble/components/widgets/invitation.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/pages/gameplay.dart';
import 'package:wibble/pages/mainmenu.dart';
import 'package:wibble/pages/private_lobby.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/lobby.dart';
import 'package:wibble/utils/soundEngine.dart';

import 'firebase/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  // Initialize audio engine
  await SoundEngine.initialize();
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

class _MyAppContentState extends State<MyAppContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SoundEngine.playBackgroundMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App is in background - pause background music
        SoundEngine.pauseBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        // App is back to foreground - resume background music
        SoundEngine.resumeBackgroundMusic();
        break;
      case AppLifecycleState.detached:
        // App is being terminated - stop all audio
        SoundEngine.stopBackgroundMusic();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wibble',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Color(0xffF2EEDB),
      ),
      home: Stack(children: [Mainmenu(), const InvitationWidget()]),
      routes: {
        '/mainmenu': (context) =>
            Stack(children: [Mainmenu(), const InvitationWidget()]),
        '/gameplay': (context) =>
            Stack(children: [Gameplay(), const InvitationWidget()]),
        '/privateLobby': (context) =>
            Stack(children: [PrivateLobby(), const InvitationWidget()]),
      },
    );
  }
}

class Store extends ChangeNotifier {
  var _lobby = getEmptyLobby();
  Lobby get lobby => _lobby;
  set lobby(Lobby newLobby) {
    _lobby = newLobby;
    notifyListeners();
  }

  var _user = User(
    id: '',
    username: '',
    rank: Rank.bronze,
    createdAt: DateTime.now(),
  );
  User get user => _user;
  set user(User newUser) {
    _user = newUser;
    notifyListeners();
    // Start invite subscription when user is set (if not already started)
    _startInviteSubscription();
  }

  var invites = <Invite>[];

  // Subscription management
  StreamSubscription<DocumentSnapshot>? lobbySubscription;
  StreamSubscription<QuerySnapshot>? invitesSubscription;
  bool _isMatchmaking = false;

  Store() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserJson = prefs.getString(UserCacheKeys.user.name);

      if (cachedUserJson != null) {
        final cachedUser = User.fromJson(jsonDecode(cachedUserJson));
        _user = cachedUser;
        notifyListeners();

        // Start invite subscription after user is initialized
        _startInviteSubscription();
      }
      // If no cached user, keep the default values already set
    } catch (e) {
      print('Error loading user from shared preferences: $e');
      // If error occurs, keep the default values already set
    }
  }

  void _startInviteSubscription() {
    // Only start subscription if user ID is not empty and subscription is not already active
    if (user.id.isEmpty || invitesSubscription != null) return;

    try {
      final inviteStream = subscribeToInvites(playerId: user.id);
      invitesSubscription = inviteStream.listen((event) {
        final data = event.docs
            .map((doc) => Invite.fromJson(doc.data()))
            .toList();

        invites = data;
        notifyListeners();
      });
    } catch (e) {
      print('Error starting invite subscription: $e');
    }
  }

  // Public method to manually start invite subscription (useful for debugging)
  void startInviteSubscription() {
    _startInviteSubscription();
  }

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
    invites.clear();
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
      this.lobby = lobby;
      notifyListeners();
    } else {
      print('❌ No ongoing lobby found');
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
        final data = event.data();
        if (data != null) {
          _lobby = Lobby.fromJson(data as Map<String, dynamic>);
          notifyListeners();
        }
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
          _lobby = Lobby.fromJson(data as Map<String, dynamic>);
          notifyListeners();
        }
      });
    } catch (error) {
      notifyListeners();
      rethrow;
    }
  }
}

//TODO doesnt resume (to menus) properly when launching for the first time
