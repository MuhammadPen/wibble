class FirestoreCollections {
  static const String multiplayer = 'multiplayer';
}
// player lobby info

typedef LobbyPlayerInfo = ({
  String userId,
  String username,
  String rank,
  DateTime createdAt,
  int score,
  int round,
  int attempts,
});
