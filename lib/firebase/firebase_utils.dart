import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/types.dart';

Future<String> createUser({required User user}) async {
  await Firestore().addDocument(
    collectionId: FirestoreCollections.users.name,
    documentId: user.id,
    data: user.toJson(),
  );
  return user.id;
}

Future<User?> getUser({required String userId}) async {
  final doc = await Firestore().getDocument(
    collectionId: FirestoreCollections.users.name,
    documentId: userId,
  );
  if (doc.exists && doc.data() != null) {
    return User.fromJson(doc.data() as Map<String, dynamic>);
  } else {
    return null;
  }
}

Future<String> createLobby({required Lobby lobby}) async {
  await Firestore().addDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobby.id,
    data: lobby.toJson(),
  );
  return lobby.id;
}

Future<void> joinLobby({
  required String lobbyId,
  required LobbyPlayerInfo playerInfo,
}) async {
  await Firestore().updateDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobbyId,
    data: {
      'players.${playerInfo.user.id}': playerInfo.toJson(),
      'playerCount': FieldValue.increment(1),
    },
  );
}

Future<void> leaveLobby({
  required String lobbyId,
  required String playerId,
}) async {
  await Firestore().updateDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobbyId,
    data: {
      'players.$playerId': FieldValue.delete(),
      'playerCount': FieldValue.increment(-1),
    },
  );
}

Future<QuerySnapshot<Map<String, dynamic>>> getOpen1v1Lobbies() async {
  final lobbies = await Firestore.instance
      .collection(FirestoreCollections.multiplayer.name)
      .where('playerCount', isEqualTo: 1)
      .get();

  return lobbies;
}

Future<QuerySnapshot<Map<String, dynamic>>> getLobbyByPlayerId({
  required String playerId,
}) async {
  final lobbies = await Firestore.instance
      .collection(FirestoreCollections.multiplayer.name)
      .where('players.$playerId', isNotEqualTo: null)
      .get();

  return lobbies;
}

Future<void> updatePlayerProgressInLobby({
  required String lobbyId,
  required String playerId,
  required int score,
  required int round,
  required int attempts,
}) async {
  await Firestore().updateDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobbyId,
    data: {
      'players.$playerId.score': score,
      'players.$playerId.round': round,
      'players.$playerId.attempts': attempts,
    },
  );
}

Future<Stream<DocumentSnapshot>> start1v1Matchmaking(
  LobbyPlayerInfo playerInfo,
) async {
  final lobbies = await getOpen1v1Lobbies();
  String? compatibleLobbyId;

  for (var lobby in lobbies.docs) {
    final players = lobby.data()['players'];
    for (var opponent in players.entries) {
      opponent = LobbyPlayerInfo.fromJson(opponent.value);
      if (opponent.user.id != playerInfo.user.id &&
          opponent.user.rank == playerInfo.user.rank) {
        compatibleLobbyId = lobby.id;
        await joinLobby(lobbyId: compatibleLobbyId, playerInfo: playerInfo);
        break;
      }
    }
    if (compatibleLobbyId != null) {
      break;
    }
  }

  // If compatible lobby is not found, create a new one
  compatibleLobbyId ??= await createLobby(
    lobby: Lobby(
      id: Uuid().v4(),
      rounds: 3,
      wordLength: 5,
      maxAttempts: 6,
      playerCount: 1,
      players: {playerInfo.user.id: playerInfo},
      startTime: DateTime.now(),
    ),
  );

  // Subscribe to the lobby
  final subscription = await Firestore().subscribeToDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: compatibleLobbyId,
  );

  return subscription;
}

Future<Lobby?> checkForOnGoingMatch({required String playerId}) async {
  final lobbies = await getLobbyByPlayerId(playerId: playerId);
  if (lobbies.docs.isEmpty) {
    return null;
  }
  return Lobby.fromJson(lobbies.docs.first.data());
}

Future<void> setLobbyStartTime({
  required String lobbyId,
  required DateTime startTime,
}) async {
  await Firestore().updateDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobbyId,
    data: {'startTime': startTime},
  );
}

Future<DateTime?> getLobbyStartTime({required String lobbyId}) async {
  var doc = await Firestore().getDocument(
    collectionId: FirestoreCollections.multiplayer.name,
    documentId: lobbyId,
  );

  if (doc.exists && doc.data() != null) {
    var data = doc.data() as Map<String, dynamic>;
    var startTimeData = data['startTime'];
    if (startTimeData != null) {
      if (startTimeData is Timestamp) {
        return startTimeData.toDate();
      } else if (startTimeData is String) {
        return DateTime.parse(startTimeData);
      }
    }
  }
  return null;
}
