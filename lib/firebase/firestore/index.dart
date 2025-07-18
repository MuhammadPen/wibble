import 'package:cloud_firestore/cloud_firestore.dart';

class Firestore {
  static FirebaseFirestore get instance => FirebaseFirestore.instance;

  // get document from firestore collection
  Future<DocumentSnapshot> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await instance.collection(collectionId).doc(documentId).get();
  }

  // get all documents from firestore collection
  Future<QuerySnapshot> getDocuments({required String collectionId}) async {
    return await instance.collection(collectionId).get();
  }

  // add document to firestore collection
  Future<void> addDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await instance.collection(collectionId).doc(documentId).set(data);
  }

  Future<void> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await instance.collection(collectionId).doc(documentId).update(data);
  }

  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    await instance.collection(collectionId).doc(documentId).delete();
  }

  Future<bool> doesDocumentExist({
    required String collectionId,
    required String documentId,
  }) async {
    final doc = await getDocument(
      collectionId: collectionId,
      documentId: documentId,
    );
    return doc.exists;
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
}
