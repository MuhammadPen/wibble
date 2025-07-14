import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../types.dart';

class Firestore {
  static FirebaseFirestore get instance => FirebaseFirestore.instance;

  // get document from firestore collection
  Future<DocumentSnapshot> _getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await instance.collection(collectionId).doc(documentId).get();
  }

  // get all documents from firestore collection
  Future<QuerySnapshot> _getDocuments({required String collectionId}) async {
    return await instance.collection(collectionId).get();
  }

  // add document to firestore collection
  Future<void> _addDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await instance.collection(collectionId).doc(documentId).set(data);
  }

  Future<void> _updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await instance.collection(collectionId).doc(documentId).update(data);
  }

  Future<void> _deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    await instance.collection(collectionId).doc(documentId).delete();
  }

  Future<Stream<DocumentSnapshot>> subscribeToDocument({
    required String collectionId,
    required String documentId,
  }) async {
    final Stream<DocumentSnapshot> stream = instance
        .collection(collectionId)
        .doc(documentId)
        .snapshots();

    return stream;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getOpen1v1Lobbies() async {
    final lobbies = await instance
        .collection(FirestoreCollections.multiplayer)
        .where('playerCount', isEqualTo: 1)
        .get();

    return lobbies;
  }

  Future<String> createLobby({
    required int playerCount,
    required LobbyPlayerInfo playerInfo,
  }) async {
    final lobbyId = Uuid().v4();
    final Map<String, dynamic> lobbyData = {
      'playerCount': playerCount,
      'players': {playerInfo.user.id: playerInfo.toJson()},
    };
    await _addDocument(
      collectionId: FirestoreCollections.multiplayer,
      documentId: lobbyId,
      data: lobbyData,
    );
    return lobbyId;
  }

  Future<void> joinLobby({
    required String lobbyId,
    required LobbyPlayerInfo playerInfo,
  }) async {
    await _updateDocument(
      collectionId: FirestoreCollections.multiplayer,
      documentId: lobbyId,
      data: {
        'players.${playerInfo.user.id}': playerInfo.toJson(),
        'playerCount': FieldValue.increment(1),
      },
    );
  }
}
