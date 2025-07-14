// starts 1v1 matchmaking

// Search multiplayer collection for lobbies with 1 player.
// In those lobbies, check the existing player info for compatibility.
// if compatible player is found, join their lobby.
// Subscribe to the lobby to the lobby.

// If compatible player is not found, create a lobby in multiplayer collection
// Subscribe to the collection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/types.dart';

Future<Stream<DocumentSnapshot>> start1v1Matchmaking(
  LobbyPlayerInfo playerInfo,
) async {
  final lobbies = await Firestore().getOpen1v1Lobbies();
  String? compatibleLobbyId;

  for (var lobby in lobbies.docs) {
    final players = lobby.data()['players'];
    for (var opponent in players.entries) {
      opponent = LobbyPlayerInfo.fromJson(opponent.value);
      if (opponent.user.id != playerInfo.user.id &&
          opponent.user.rank == playerInfo.user.rank) {
        compatibleLobbyId = lobby.id;
        await Firestore().joinLobby(
          lobbyId: compatibleLobbyId,
          playerInfo: playerInfo,
        );
        break;
      }
    }
    if (compatibleLobbyId != null) {
      break;
    }
  }

  // If compatible lobby is not found, create a new one
  compatibleLobbyId ??= await Firestore().createLobby(
    playerCount: 1,
    playerInfo: playerInfo,
  );

  // Subscribe to the lobby
  final subscription = await Firestore().subscribeToDocument(
    collectionId: FirestoreCollections.multiplayer,
    documentId: compatibleLobbyId,
  );

  return subscription;
}
