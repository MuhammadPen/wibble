// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpjs_pro_plugin/fpjs_pro_plugin.dart';
import 'package:fpjs_pro_plugin/region.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wibble/components/how_to_play.dart';
import 'package:wibble/components/user_card.dart';
import 'package:wibble/env/env.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/main.dart';
import 'package:wibble/styles/button.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/identity.dart';
import 'package:wibble/utils/lobby.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedResumeMatch) {
        setState(() {
          _hasCheckedResumeMatch = true;
        });
        store.resumeMatch();
      }
    });

    return Scaffold(
      appBar: null,
      body: Center(
        child: isMatchmaking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    store.lobbyData.playerCount >= store.lobbyData.maxPlayers
                        ? 'All players connected, starting match'
                        : '${store.lobbyData.playerCount} out of ${store.lobbyData.maxPlayers} connected',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text("cancel"),
                    onPressed: () async {
                      // NOTE on all buttons: loading - disabled when loading
                      try {
                        await leaveLobby(
                          lobbyId: store.lobbyData.id,
                          playerId: store.user.id,
                        );
                        store.isMatchmaking = false;
                        store.lobbyData = getEmptyLobby();
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Welcome message
                  if (store.user.username.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          UserCard(user: store.user),
                        ],
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
                    onPressed: () async {
                      await store.createPrivateLobby();
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

  void initFingerprint() async {
    await FpjsProPlugin.initFpjs(
      Env.FINGERPRINT_API_KEY, // insert your API key here
      region: Region.us, // Insert the data region of your Fingerprint workspace
    );
    final user = await identifyUser(context: context);
    if (user != null) {
      final store = context.read<Store>();
      store.user = user; // Set it in the store immediately
      setState(() {
        identifiedUser = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initFingerprint();
    });

    // Listen to store changes
    final store = context.read<Store>();
    store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString(UserCacheKeys.user.name);
    final store = context.read<Store>();

    // Only check lobby status if we have a valid lobby with an ID
    if (store.lobbyData.id.isNotEmpty) {
      if (cachedUser == null) {
        return;
      }
      if (store.lobbyData.players.isEmpty) {
        return;
      }

      // If on a private lobby and the game has not started, take me to the private lobby page
      if (store.lobbyData.type == LobbyType.private &&
          store.lobbyData.startTime == null) {
        Navigator.pushNamed(context, "/${Routes.privateLobby.name}");
        return;
      }

      // If on a private lobby and the game has started, take me to the gameplay page
      if (store.lobbyData.type == LobbyType.private &&
          store.lobbyData.startTime != null) {
        Navigator.pushNamed(context, "/${Routes.gameplay.name}");
        return;
      }

      // Check if lobby is full
      final isLobbyFull =
          store.lobbyData.playerCount >= store.lobbyData.maxPlayers;
      if (isLobbyFull && !_hasNavigated) {
        _hasNavigated = true;
        store.isMatchmaking = false;
        Navigator.pushNamed(context, "/${Routes.gameplay.name}");
        return;
      }

      // If user is in lobby but lobby is not full, show matchmaking state
      final isPlayerInLobby = store.lobbyData.players.containsKey(
        User.fromJson(jsonDecode(cachedUser)).id,
      );
      if (isPlayerInLobby && !isLobbyFull && !_hasNavigated) {
        // Only set matchmaking to true if it's not already true (prevent infinite loop)
        if (!store.isMatchmaking) {
          store.isMatchmaking = true;
        }
      }
    }
  }
}
