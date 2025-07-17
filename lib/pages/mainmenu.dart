// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpjs_pro_plugin/error.dart';
import 'package:fpjs_pro_plugin/fpjs_pro_plugin.dart';
import 'package:fpjs_pro_plugin/region.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/components/how_to_play.dart';
import 'package:wibble/components/user_form.dart';
import 'package:wibble/env/env.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/main.dart';
import 'package:wibble/types.dart';

class Mainmenu extends StatefulWidget {
  const Mainmenu({super.key});

  @override
  State<Mainmenu> createState() => _MainmenuState();
}

class _MainmenuState extends State<Mainmenu> {
  bool _hasNavigated = false; // Add flag to prevent multiple navigations
  User? identifiedUser;
  bool _hasCheckedResumeMatch = false;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Store>(context);
    final isMatchmaking = store.isMatchmaking;

    if (identifiedUser != null) {
      store.user = identifiedUser!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedResumeMatch) {
        setState(() {
          _hasCheckedResumeMatch = true;
        });
        store.resumeMatch();
      }
    });

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: TextStyle(fontSize: 16),
      elevation: 0,
    );

    return Scaffold(
      appBar: null,
      body: Center(
        child: isMatchmaking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Finding opponents...', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("cancel"),
                    onPressed: () async {
                      try {
                        print('Cancelling matchmaking...');
                        await leaveLobby(
                          lobbyId: store.lobbyData.id,
                          playerId: store.user.id,
                        );
                        store.isMatchmaking = false;
                        store.lobbyData = Lobby(
                          id: '',
                          rounds: 3,
                          wordLength: 5,
                          maxAttempts: 6,
                          playerCount: 0,
                          maxPlayers: 2,
                          type: LobbyType.oneVOne,
                          players: {},
                          startTime: DateTime.now(),
                        );
                      } catch (e, stackTrace) {
                        print('Error in matchmaking: $e');
                        print('Stack trace: $stackTrace');
                      }
                    },
                    style: buttonStyle,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome message
                  if (store.user.username.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Text(
                        'Welcome ${store.user.username}!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("1v1"),
                    onPressed: store.user.id.isEmpty
                        ? null
                        : () async {
                            try {
                              print('Starting 1v1 matchmaking...');
                              await store.searchForGame(
                                type: LobbyType.oneVOne,
                              );
                            } catch (e, stackTrace) {
                              print('Error in matchmaking: $e');
                              print('Stack trace: $stackTrace');
                            }
                          },
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("5v5"),
                    onPressed: store.user.id.isEmpty
                        ? null
                        : () async {
                            try {
                              print('Starting 5v5 matchmaking...');
                              await store.searchForGame(type: LobbyType.custom);
                            } catch (e, stackTrace) {
                              print('Error in matchmaking: $e');
                              print('Stack trace: $stackTrace');
                            }
                          },
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("Private lobby"),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        "/${Routes.privateLobby.name}",
                      );
                    },
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.help),
                    label: Text("How to play"),
                    onPressed: () {
                      HowToPlayDialog.show(context);
                    },
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

  @override
  void dispose() {
    final store = context.read<Store>();
    store.removeListener(_onStoreChanged);
    super.dispose();
  }

  // Identify visitor
  void identifyUser() async {
    final prefs = await SharedPreferences.getInstance();
    var cachedUser = prefs.getString(UserCacheKeys.user.name);

    if (cachedUser != null) {
      try {
        setState(() {
          identifiedUser = User.fromJson(jsonDecode(cachedUser));
        });
      } catch (e) {
        print("🐾 error: $e");
      }
      return;
    }

    try {
      var visitorId = await FpjsProPlugin.getVisitorId();

      var user = await getUser(userId: visitorId ?? Uuid().v4());

      if (user != null) {
        setState(() {
          identifiedUser = user;
        });
        //cache user
        await prefs.setString(
          UserCacheKeys.user.name,
          jsonEncode(user.toJson()),
        );
      } else {
        UserFormDialog.show(
          context,
          onSubmit: (username) async {
            final user = User(
              id: visitorId ?? Uuid().v4(),
              username: username,
              rank: Rank.bronze,
              createdAt: DateTime.now(),
            );
            await createUser(user: user);

            //cache user
            await prefs.setString(
              UserCacheKeys.user.name,
              jsonEncode(user.toJson()),
            );

            setState(() {
              identifiedUser = user;
            });
          },
        );
      }
    } on FingerprintProError catch (e) {
      // Process the error
      print('Error identifying visitor: $e');
    }
  }

  void initFingerprint() async {
    await FpjsProPlugin.initFpjs(
      Env.FINGERPRINT_API_KEY, // insert your API key here
      region: Region.us, // Insert the data region of your Fingerprint workspace
    );
    identifyUser();
  }

  @override
  void initState() {
    super.initState();
    initFingerprint();

    // Listen to store changes
    final store = context.read<Store>();
    store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString(UserCacheKeys.user.name);
    final store = context.read<Store>();
    final isLobbyFull =
        store.lobbyData.playerCount >= store.lobbyData.maxPlayers;
    if (isLobbyFull && !_hasNavigated) {
      _hasNavigated = true;
      store.isMatchmaking = false;
      Navigator.pushNamed(context, "/${Routes.gameplay.name}");
      return;
    }
    if (cachedUser != null) {
      final isPlayerInLobby = store.lobbyData.players.containsKey(
        User.fromJson(jsonDecode(cachedUser)).id,
      );
      if (isPlayerInLobby && !_hasNavigated) {
        _hasNavigated = true;
        store.isMatchmaking = true;
      }
    }
  }
}
