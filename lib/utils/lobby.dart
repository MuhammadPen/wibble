import 'package:wibble/types.dart';

Lobby getEmptyLobby() {
  return Lobby(
    id: '',
    rounds: 3,
    wordLength: 5,
    maxAttempts: 6,
    playerCount: 1,
    players: {},
    startTime: null,
    maxPlayers: 2,
    type: LobbyType.oneVOne,
  );
}
