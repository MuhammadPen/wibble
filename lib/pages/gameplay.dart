import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/components/clock.dart';
import 'package:wibble/components/countdown.dart';
import 'package:wibble/components/dialog.dart';
import 'package:wibble/components/keyboard_widget.dart';
import 'package:wibble/components/word_grid.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/main.dart';
import 'package:wibble/types.dart';
import 'dart:async';

class GameStatus extends StatelessWidget {
  final int remainingSeconds;
  final User user;
  final int playerScore;
  final LobbyPlayerInfo? opponent;
  const GameStatus({
    super.key,
    required this.remainingSeconds,
    required this.user,
    required this.playerScore,
    required this.opponent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          ClockWidget(
            remainingSeconds: remainingSeconds,
            totalSeconds: remainingSeconds,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your score",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$playerScore',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opponent?.user.username ?? 'Opponent',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${opponent?.score ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Gameplay extends StatefulWidget {
  const Gameplay({super.key});

  @override
  State<Gameplay> createState() => _GameplayState();
}

class _GameplayState extends State<Gameplay> {
  // Game state variables
  List<List<String>> _guessGrid = [];
  final List<int> _cursorPosition = [0, 0]; // [row, column]
  bool _startGamePressed = false;
  int _currentRound = 0;
  String _currentWord = "";
  int _score = 0;
  bool _isCurrentRowFilled = false;
  bool _areAttemptsOver = false;
  bool _showCurrentWord = false;
  late FocusNode _focusNode;

  // Timer variables
  Timer? _gameTimer;
  final int _roundDuration = 180; // seconds
  int _remainingSeconds = 180; // 3 minutes = 180 seconds
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _initializeGameGrid();
    _selectWord();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  int _getPlayerScore() {
    final store = context.read<Store>();
    final lobbyData = context.read<Store>().lobbyData;

    final LobbyPlayerInfo? myPlayer = lobbyData.players[store.user.id];

    final int myScore = myPlayer?.score ?? _score;

    return myScore;
  }

  int _getOpponentScore() {
    final store = context.read<Store>();
    final lobbyData = context.read<Store>().lobbyData;

    LobbyPlayerInfo? opponent;
    try {
      opponent = lobbyData.players.values.firstWhere(
        (e) => e.user.id != store.user.id,
      );
    } catch (e) {
      print('No opponent found');
    }
    final int opponentScore = opponent?.score ?? 0;

    return opponentScore;
  }

  void _startGameTimer() async {
    final store = context.read<Store>();

    var lobbyStartTime = await getLobbyStartTime(lobbyId: store.lobbyData.id);
    if (lobbyStartTime == null) {
      // set lobby start time
      store.lobbyData.startTime = DateTime.now();
      await setLobbyStartTime(
        lobbyId: store.lobbyData.id,
        startTime: DateTime.now(),
      );
    } else {
      store.lobbyData.startTime = lobbyStartTime;
    }

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedTime = DateTime.now().difference(store.lobbyData.startTime);
      if (_roundDuration - elapsedTime.inSeconds <= 0) {
        _handleTimeUp();
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = _roundDuration - elapsedTime.inSeconds;
      });
    });
  }

  void _handleTimeUp() async {
    setState(() {
      _areAttemptsOver = true;
    });

    final store = context.read<Store>();
    final lobbyData = store.lobbyData;

    final int myScore = _getPlayerScore();
    final int opponentScore = _getOpponentScore();

    //leave lobby
    await leaveLobby(lobbyId: lobbyData.id, playerId: store.user.id);
    //clear lobby in store
    store.lobbyData = Lobby(
      id: '',
      rounds: 3,
      wordLength: 5,
      maxAttempts: 6,
      playerCount: 1,
      players: {},
      startTime: DateTime.now(),
      maxPlayers: 2,
      type: LobbyType.oneVOne,
    );

    if (myScore > opponentScore) {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameWon.name,
        message: 'You win!',
        buttonText: 'Back to Menu',
        onClose: () {
          Navigator.pushNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    } else if (myScore < opponentScore) {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameLost.name,
        message: 'You lost :(',
        buttonText: 'Back to Menu',
        onClose: () {
          Navigator.pushNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    } else {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameTied.name,
        message: 'Game tied!',
        buttonText: 'Back to Menu',
        onClose: () {
          Navigator.pushNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    }

    // show updated ranks
  }

  void _selectWord() async {
    final String wordList = await DefaultAssetBundle.of(
      context,
    ).loadString('lib/assets/5-letter-words.txt');
    final List<String> words = wordList.split('\n');
    setState(() {
      _currentWord = words[DateTime.now().millisecondsSinceEpoch % words.length]
          .toUpperCase();
    });
  }

  void _updateScore() {
    final store = context.read<Store>();
    final lobbyData = store.lobbyData;

    final attemptsUsed =
        _cursorPosition[0] + 1; // +1 because cursor position is 0-indexed

    // Calculate score based on attempts used
    // Formula: 100 - ((attemptsUsed - 1) * (100 / (maxAttempts + 1)))
    // This gives 100 points for 1 attempt, decreasing linearly
    final int scoreForThisWord =
        (100 - ((attemptsUsed - 1) * (100 / (lobbyData.maxAttempts + 1))))
            .round();

    setState(() {
      // there is a better way to do this, but this is a quick fix
      // _score is for local calculations and display, lobbyData is for sending over to the other player
      _score += scoreForThisWord;
      lobbyData.players[store.user.id]?.score += scoreForThisWord;
    });
  }

  /// Initialize the game grid based on lobby settings
  void _initializeGameGrid() {
    final appStore = context.read<Store>();
    final wordLength = appStore.lobbyData.wordLength;
    final maxAttempts = appStore.lobbyData.maxAttempts;

    _guessGrid = List.generate(
      maxAttempts,
      (_) => List.generate(wordLength, (_) => ""),
    );
  }

  /// Handle key press from the keyboard
  void _handleKeyTap(String key) {
    if (_isCurrentRowFilled || _areAttemptsOver || _isTimeUp) return;

    setState(() {
      final wordLength = _guessGrid[0].length;
      final isAtEndOfWord = _cursorPosition[1] == wordLength;

      if (!isAtEndOfWord) {
        _guessGrid[_cursorPosition[0]][_cursorPosition[1]] = key;
        _cursorPosition[1]++;

        // Check if word is now complete
        if (_cursorPosition[1] == wordLength) {
          _isCurrentRowFilled = true;
        }
      }
    });
  }

  /// Handle delete key press
  void _handleDelete() {
    if (_isTimeUp) return;

    final wordLength = _guessGrid[0].length;
    final isAtStartOfWord = _cursorPosition[1] == 0;
    final isAtEndOfWord = _cursorPosition[1] == wordLength;

    setState(() {
      if (isAtStartOfWord) {
        // At start, just clear the current position
        _guessGrid[_cursorPosition[0]][_cursorPosition[1]] = "";
      } else {
        // Delete the previous character
        // at the end of a word, the cursor index is 1 more than the word length. so we move it back by 1
        final columnToDelete = isAtEndOfWord
            ? _cursorPosition[1] - 1
            : _cursorPosition[1];
        _guessGrid[_cursorPosition[0]][columnToDelete] = "";
        _cursorPosition[1]--;

        // If we were at the end of a complete word, mark it as incomplete
        if (isAtEndOfWord) {
          _isCurrentRowFilled = false;
        }
      }
    });
  }

  /// Handle enter key press to submit the current word
  void _handleEnter() async {
    if (!_isCurrentRowFilled || _areAttemptsOver || _isTimeUp) return;

    // Add word validation
    var currentAttemptArray = _guessGrid[_cursorPosition[0]];
    var currentAttempt = currentAttemptArray.join('');

    // correct attempt
    if (currentAttempt == _currentWord) {
      // update score
      _updateScore();
      // increment round
      // reset game state
      setState(() {
        _currentRound++;
        _cursorPosition[0] = 0;
        _cursorPosition[1] = 0;
        _isCurrentRowFilled = false;
        _areAttemptsOver = false;
      });
      _initializeGameGrid();
      // select new word
      _selectWord();
    } else {
      setState(() {
        // Move to the next row
        _cursorPosition[0]++;
        _cursorPosition[1] = 0;
        _isCurrentRowFilled = false;
      });

      // Check if we've reached the maximum number of attempts
      if (_cursorPosition[0] >= _guessGrid.length) {
        _showCurrentWord = true;
        // wait for 3 seconds
        await Future.delayed(const Duration(seconds: 3), () {
          _showCurrentWord = false;
        });
        setState(() {
          _cursorPosition[0] = 0;
          _cursorPosition[1] = 0;
        });
        _selectWord();
        _initializeGameGrid();

        // _areAttemptsOver = true;
      }
    }

    // update player progress in lobby
    // if the lobby doesnt exist this will just error out. can ignore that
    updatePlayerProgressInLobby(
      lobbyId: context.read<Store>().lobbyData.id,
      playerId: context.read<Store>().user.id,
      score: _getPlayerScore(),
      round: _currentRound,
      attempts: _cursorPosition[0] + 1,
    ).catchError((error) {
      print('Failed to update progress: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<Store>();
    final lobbyData = store.lobbyData;
    LobbyPlayerInfo? opponent;
    try {
      opponent = lobbyData.players.values.firstWhere(
        (e) => e.user.id != store.user.id,
      );
    } catch (e) {
      print('No opponent found');
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave game?'),
                content: const Text('Are you sure you want to resign?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Leave'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          appBar: null,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GameStatus(
                    remainingSeconds: _remainingSeconds,
                    user: store.user,
                    playerScore: _score,
                    opponent: opponent,
                  ),
                  SizedBox(height: 20),
                  if (_startGamePressed)
                    CountdownWidget(
                      durationInSeconds: 3,
                      onCountdownComplete: () {
                        _startGameTimer();
                      },
                    ),
                  if (_showCurrentWord)
                    Text(
                      'Word was: $_currentWord',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  // Word grid display
                  WordGrid(
                    guessGrid: _guessGrid,
                    cursorPosition: _cursorPosition,
                    isWordComplete: _isCurrentRowFilled,
                    targetWord: _currentWord,
                  ),
                  // Keyboard
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: KeyboardWidget(
                      onKeyTap: _handleKeyTap,
                      onDelete: _handleDelete,
                      onEnter: _handleEnter,
                      isCurrentWordComplete: _isCurrentRowFilled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// take action after time is up.
// compare score with opponent
// show winner
// show updated ranks
// go to main menu

//also I need to add handling if you dont find anyone at your rank, look for someone without rank restriction
