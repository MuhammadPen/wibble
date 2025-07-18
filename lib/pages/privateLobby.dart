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

  @override
  Widget build(BuildContext context) {
    final store = context.read<Store>();
    final lobby = store.lobbyData;

    return Scaffold(
      appBar: AppBar(title: const Text('Private Lobby')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 50,
        children: [
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
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: buttonStyle,
                onPressed: _printHello,
                child: const Text('Start game'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
