// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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

LobbyPlayerInfo _$LobbyPlayerInfoFromJson(Map<String, dynamic> json) =>
    LobbyPlayerInfo(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      score: (json['score'] as num).toInt(),
      round: (json['round'] as num).toInt(),
      attempts: (json['attempts'] as num).toInt(),
    );

Map<String, dynamic> _$LobbyPlayerInfoToJson(LobbyPlayerInfo instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'score': instance.score,
      'round': instance.round,
      'attempts': instance.attempts,
    };
