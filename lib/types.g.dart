// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) => Invite(
  id: json['id'] as String,
  lobbyId: json['lobbyId'] as String,
  sender: User.fromJson(json['sender'] as Map<String, dynamic>),
  receiverId: json['receiverId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'id': instance.id,
  'lobbyId': instance.lobbyId,
  'sender': instance.sender.toJson(),
  'receiverId': instance.receiverId,
  'createdAt': instance.createdAt.toIso8601String(),
};

Lobby _$LobbyFromJson(Map<String, dynamic> json) => Lobby(
  id: json['id'] as String,
  maxAttempts: (json['maxAttempts'] as num).toInt(),
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  playerCount: (json['playerCount'] as num).toInt(),
  players: (json['players'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, LobbyPlayerInfo.fromJson(e as Map<String, dynamic>)),
  ),
  rounds: (json['rounds'] as num).toInt(),
  startTime: const TimestampConverter().fromJson(json['startTime']),
  type: $enumDecode(_$LobbyTypeEnumMap, json['type']),
  wordLength: (json['wordLength'] as num).toInt(),
);

Map<String, dynamic> _$LobbyToJson(Lobby instance) => <String, dynamic>{
  'id': instance.id,
  'rounds': instance.rounds,
  'wordLength': instance.wordLength,
  'maxAttempts': instance.maxAttempts,
  'playerCount': instance.playerCount,
  'maxPlayers': instance.maxPlayers,
  'type': _$LobbyTypeEnumMap[instance.type]!,
  'startTime': const TimestampConverter().toJson(instance.startTime),
  'players': instance.players.map((k, e) => MapEntry(k, e.toJson())),
};

const _$LobbyTypeEnumMap = {
  LobbyType.oneVOne: 'oneVOne',
  LobbyType.custom: 'custom',
  LobbyType.private: 'private',
};

LobbyPlayerInfo _$LobbyPlayerInfoFromJson(Map<String, dynamic> json) =>
    LobbyPlayerInfo(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      score: (json['score'] as num).toInt(),
      round: (json['round'] as num).toInt(),
      attempts: (json['attempts'] as num).toInt(),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );

Map<String, dynamic> _$LobbyPlayerInfoToJson(LobbyPlayerInfo instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'score': instance.score,
      'round': instance.round,
      'attempts': instance.attempts,
      'isAdmin': instance.isAdmin,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String,
  rank: $enumDecode(_$RankEnumMap, json['rank']),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'rank': _$RankEnumMap[instance.rank]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$RankEnumMap = {
  Rank.bronze: 'bronze',
  Rank.silver: 'silver',
  Rank.gold: 'gold',
  Rank.platinum: 'platinum',
  Rank.diamond: 'diamond',
  Rank.master: 'master',
  Rank.grandmaster: 'grandmaster',
};
