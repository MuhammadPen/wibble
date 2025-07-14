import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'types.dart';

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

  Future<void> createLobby({required LobbyPlayerInfo playerInfo}) async {
    await _addDocument(
      collectionId: FirestoreCollections.multiplayer,
      documentId: Uuid().v4(),
      data: {playerInfo.userId: playerInfo},
    );
  }

  Future<void> joinLobby({
    required LobbyPlayerInfo playerInfo,
    required String lobbyId,
  }) async {
    await _updateDocument(
      collectionId: FirestoreCollections.multiplayer,
      documentId: lobbyId,
      data: {playerInfo.userId: playerInfo},
    );
  }
}
