// NOTE - Run `dart run build_runner build` after creating a `@JsonSerializable()` class to generate json methods

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'types.g.dart';

// Custom converter to handle both Firestore Timestamp and String for DateTime
class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    throw ArgumentError(
      'Invalid type for DateTime conversion: ${json.runtimeType}',
    );
  }

  @override
  dynamic toJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

enum DialogKeys { gameWon, gameLost, gameTied, howToPlay, startGame }

enum FirestoreCollections { users, multiplayer, invites }

enum LobbyType { oneVOne, custom, private }

enum Rank { bronze, silver, gold, platinum, diamond, master, grandmaster }

enum Routes { mainmenu, gameplay, privateLobby }

@JsonSerializable(explicitToJson: true)
class Invite {
  final String id;
  final String lobbyId;
  final User sender;
  final String receiverId;
  final DateTime createdAt;

  Invite({
    required this.id,
    required this.lobbyId,
    required this.sender,
    required this.receiverId,
    required this.createdAt,
  });

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);
  Map<String, dynamic> toJson() => _$InviteToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Lobby {
  final String id;
  final int rounds;
  final int wordLength;
  final int maxAttempts;
  final int playerCount;
  final int maxPlayers;
  final LobbyType type;
  @TimestampConverter()
  DateTime? startTime;
  final Map<String, LobbyPlayerInfo> players;
  Lobby({
    required this.id,
    required this.maxAttempts,
    required this.maxPlayers,
    required this.playerCount,
    required this.players,
    required this.rounds,
    this.startTime,
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
  bool? isAdmin;

  LobbyPlayerInfo({
    required this.user,
    required this.score,
    required this.round,
    required this.attempts,
    this.isAdmin = false,
  });

  // Generated methods:
  factory LobbyPlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$LobbyPlayerInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LobbyPlayerInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class User {
  final String id;
  String username;
  final Rank rank;
  final DateTime createdAt;

  User({
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
