import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/components/widgets/lobby_status.dart';
import 'package:wibble/components/widgets/invite_user_form.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/main.dart';
import 'package:wibble/styles/button.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/lobby.dart';

class PrivateLobby extends StatefulWidget {
  const PrivateLobby({super.key});

  @override
  State<PrivateLobby> createState() => _PrivateLobbyState();
}

class _PrivateLobbyState extends State<PrivateLobby> {
  late Store _store;
  var _showUserDoesNotExist = false;
  var _showInviteSent = false;

  @override
  void initState() {
    super.initState();
    _store = context.read<Store>();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final lobby = store.lobby;
    final isAdmin =
        lobby.players.containsKey(store.user.id) &&
        lobby.players[store.user.id]?.isAdmin == true;

    return Scaffold(
      appBar: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 50,
        children: [
          SizedBox(height: 20),
          LobbyStatus(lobby: lobby, currentUserId: store.user.id),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: InviteUserForm(
                onInvite: (userId) async {
                  final doesUserExist = await Firestore().doesDocumentExist(
                    collectionId: FirestoreCollections.users.name,
                    documentId: userId,
                  );

                  if (!doesUserExist) {
                    setState(() {
                      _showUserDoesNotExist = true;
                    });
                    // after 3 seconds set it to false
                    Future.delayed(const Duration(seconds: 3), () {
                      setState(() {
                        _showUserDoesNotExist = false;
                      });
                    });
                    return;
                  }

                  final inviteToSend = Invite(
                    id: Uuid().v4(),
                    lobbyId: lobby.id,
                    sender: store.user,
                    receiverId: userId,
                    createdAt: DateTime.now(),
                  );

                  await invitePlayer(invite: inviteToSend);
                  setState(() {
                    _showInviteSent = true;
                  });
                  // after 3 seconds set it to false
                  Future.delayed(const Duration(seconds: 3), () {
                    setState(() {
                      _showInviteSent = false;
                    });
                  });
                },
              ),
            ),
          ),
          if (_showUserDoesNotExist)
            Text(
              "User does not exist",
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          if (_showInviteSent)
            Text(
              "Invite sent",
              style: TextStyle(color: Colors.green),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 20),
          if (isAdmin)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () async {
                    // Set the lobby start time in Firestore
                    // The navigation listener will handle the navigation
                    await setLobbyStartTime(
                      lobbyId: lobby.id,
                      startTime: DateTime.now(),
                    );
                  },
                  child: const Text('Start game'),
                ),
              ],
            ),
          if (isAdmin)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () async {
                    await cancelPrivateLobby(lobbyId: lobby.id);
                    store.lobby = getEmptyLobby();
                    store.cancelLobbySubscription();
                    Navigator.pushReplacementNamed(
                      context,
                      "/${Routes.mainmenu.name}",
                    );
                  },
                  child: const Text('Cancel lobby'),
                ),
              ],
            ),
          if (!isAdmin)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () async {
                    await leaveLobby(
                      lobbyId: lobby.id,
                      playerId: store.user.id,
                    );
                    store.lobby = getEmptyLobby();
                    store.cancelLobbySubscription();
                    Navigator.pushReplacementNamed(
                      context,
                      "/${Routes.mainmenu.name}",
                    );
                  },
                  child: const Text('Leave lobby'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onStoreChanged() {
    // fetch the store again to get updated values
    final store = context.read<Store>();
    //get current route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    print("🔴 currentRoute: $currentRoute");
    if (currentRoute == "/${Routes.privateLobby.name}") {
      return;
    }

    // If on a private lobby and the game has started, take me to the gameplay page
    if (store.lobby.type == LobbyType.private &&
        store.lobby.startTime != null) {
      Navigator.pushReplacementNamed(context, "/${Routes.gameplay.name}");
      return;
    }
  }
}

// leave private lobby screen when admin cancels the lobby
