// NOTE - Run `dart run build_runner build` after creating a `@JsonSerializable()` class to generate json methods

import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

enum DialogKeys { gameWon, gameLost, gameTied, howToPlay }

enum FirestoreCollections { users, multiplayer }

enum LobbyType { oneVOne, custom }

enum Rank { bronze, silver, gold, platinum, diamond, master, grandmaster }

enum Routes { mainmenu, gameplay, privateLobby }

@JsonSerializable(explicitToJson: true)
class Lobby {
  final String id;
  final int rounds;
  final int wordLength;
  final int maxAttempts;
  final int playerCount;
  final int maxPlayers;
  final LobbyType type;
  DateTime startTime;
  final Map<String, LobbyPlayerInfo> players;
  Lobby({
    required this.id,
    required this.maxAttempts,
    required this.maxPlayers,
    required this.playerCount,
    required this.players,
    required this.rounds,
    required this.startTime,
    required this.type,
    required this.wordLength,
  });

  // Generated methods:
  factory Lobby.fromJson(Map<String, dynamic> json) => _$LobbyFromJson(json);
  Map<String, dynamic> toJson() => _$LobbyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LobbyPlayerInfo {
  final User user;
  int score;
  int round;
  int attempts;

  LobbyPlayerInfo({
    required this.user,
    required this.score,
    required this.round,
    required this.attempts,
  });

  // Generated methods:
  factory LobbyPlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$LobbyPlayerInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LobbyPlayerInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class User {
  final String id;
  final String username;
  final Rank rank;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.rank,
    required this.createdAt,
  });

  // Generated methods:
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

enum UserCacheKeys { user }
