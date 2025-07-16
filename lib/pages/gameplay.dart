import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/components/clock.dart';
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
  final LobbyPlayerInfo? opponent;
  const GameStatus({
    super.key,
    required this.remainingSeconds,
    required this.user,
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
                    Consumer<Store>(
                      builder: (context, store, child) {
                        final currentPlayer = store.lobbyData.players[user.id];
                        return Text(
                          '${currentPlayer?.score ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
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
  int _currentRound = 0;
  int _score = 0;
  String _currentWord = "";
  bool _isCurrentWordComplete = false;
  bool _areAttemptsOver = false;
  late FocusNode _focusNode;

  // Timer variables
  Timer? _gameTimer;
  int _remainingSeconds = 3; // 3 minutes = 180 seconds
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _initializeGameGrid();
    _selectWord();
    _focusNode = FocusNode();
    _startGameTimer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isTimeUp = true;
          _handleTimeUp();
          timer.cancel();
        }
      });
    });
  }

  void _handleTimeUp() async {
    setState(() {
      _areAttemptsOver = true;
    });

    final store = context.read<Store>();

    // compare score with opponent
    // Compare the player's score with the opponent's score.
    // This assumes you have access to the opponent's score via your lobby/store.
    final lobbyData = context.read<Store>().lobbyData;

    final LobbyPlayerInfo? myPlayer = lobbyData.players[store.user.id];
    LobbyPlayerInfo? opponent;
    try {
      opponent = lobbyData.players.values.firstWhere(
        (e) => e.user.id != store.user.id,
      );
    } catch (e) {
      print('No opponent found');
    }

    final int myScore = myPlayer?.score ?? _score;
    final int opponentScore = opponent?.score ?? 0;

    //leave lobby
    await leaveLobby(lobbyId: lobbyData.id, playerId: store.user.id);
    //clear lobby in store
    store.lobbyData = Lobby(
      id: '1234567890',
      rounds: 3,
      wordLength: 5,
      maxAttempts: 6,
      playerCount: 1,
      players: {},
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
    final maxAttempts = context.read<Store>().lobbyData.maxAttempts;
    final attemptsUsed =
        _cursorPosition[0] + 1; // +1 because cursor position is 0-indexed

    // Calculate score based on attempts used
    // More attempts = lower score, fewer attempts = higher score
    // Formula: 100 - ((attemptsUsed - 1) * (100 / maxAttempts))
    // This gives 100 points for 1 attempt, decreasing linearly to 0 for maxAttempts
    final int scoreForThisWord =
        (100 - ((attemptsUsed - 1) * (100 / maxAttempts))).round();

    setState(() {
      _score += scoreForThisWord;
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
    if (_isCurrentWordComplete || _areAttemptsOver || _isTimeUp) return;

    setState(() {
      final wordLength = _guessGrid[0].length;
      final isAtEndOfWord = _cursorPosition[1] == wordLength;

      if (!isAtEndOfWord) {
        _guessGrid[_cursorPosition[0]][_cursorPosition[1]] = key;
        _cursorPosition[1]++;

        // Check if word is now complete
        if (_cursorPosition[1] == wordLength) {
          _isCurrentWordComplete = true;
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
          _isCurrentWordComplete = false;
        }
      }
    });
  }

  /// Handle enter key press to submit the current word
  void _handleEnter() {
    if (!_isCurrentWordComplete || _areAttemptsOver || _isTimeUp) return;

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
        _isCurrentWordComplete = false;
        _areAttemptsOver = false;
      });
      _initializeGameGrid();
      // select new word
      _selectWord();
      return;
    }

    setState(() {
      // Move to the next row
      _cursorPosition[0]++;
      _cursorPosition[1] = 0;
      _isCurrentWordComplete = false;

      // Check if we've reached the maximum number of attempts
      if (_cursorPosition[0] >= _guessGrid.length) {
        _areAttemptsOver = true;
      }
    });

    // update player progress in lobby
    // if the lobby doesnt exist this will just error out. can ignore that
    updatePlayerProgressInLobby(
      lobbyId: context.read<Store>().lobbyData.id,
      playerId: context.read<Store>().user.id,
      score: _score,
      round: _currentRound,
      attempts: _cursorPosition[0] + 1,
    ).catchError((error) {
      print('Failed to update progress: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // lobbyData
    final lobbyData = context.read<Store>().lobbyData;
    LobbyPlayerInfo? opponent;
    try {
      opponent = lobbyData.players.values.firstWhere(
        (e) => e.user.id != context.read<Store>().user.id,
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
          appBar: AppBar(title: const Text('Wibble')),
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GameStatus(
                    remainingSeconds: _remainingSeconds,
                    user: context.read<Store>().user,
                    opponent: opponent,
                  ),
                  // Word grid display
                  WordGrid(
                    guessGrid: _guessGrid,
                    cursorPosition: _cursorPosition,
                    isWordComplete: _isCurrentWordComplete,
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
                      isCurrentWordComplete: _isCurrentWordComplete,
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
