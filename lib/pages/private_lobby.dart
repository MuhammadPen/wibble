import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/components/lobby_status.dart';
import 'package:wibble/components/invite_user_form.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/main.dart';
import 'package:wibble/styles/button.dart';
import 'package:wibble/types.dart';

class PrivateLobby extends StatefulWidget {
  const PrivateLobby({super.key});

  @override
  State<PrivateLobby> createState() => _PrivateLobbyState();
}

class _PrivateLobbyState extends State<PrivateLobby> {
  void _printHello() async {}
  var _showUserDoesNotExist = false;
  var _showInviteSent = false;

  @override
  Widget build(BuildContext context) {
    final store = context.read<Store>();
    final lobby = store.lobbyData;
    final isAdmin =
        lobby.players.containsKey(store.user.id) &&
        lobby.players[store.user.id]?.isAdmin == true;

    print(isAdmin);

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
                    senderId: store.user.id,
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
                  onPressed: () {
                    Navigator.pushNamed(context, "/${Routes.gameplay.name}");
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
                    Navigator.pushNamed(context, "/${Routes.mainmenu.name}");
                  },
                  child: const Text('Cancel lobby'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
