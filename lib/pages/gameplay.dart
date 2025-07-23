import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/ui/countdown.dart';
import 'package:wibble/components/ui/dialog.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/components/widgets/game_status.dart';
import 'package:wibble/components/widgets/keyboard_widget.dart';
import 'package:wibble/components/widgets/word_grid.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/main.dart';
import 'package:wibble/styles/text.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/lobby.dart';

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
  String _currentWord = "";
  int _score = 0;
  bool _isCurrentRowFilled = false;
  bool _areAttemptsOver = false;
  bool _showCurrentWord = true;
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final lobbyData = store.lobby;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.transparent,
                content: ShadowContainer(
                  backgroundColor: Color(0xffF2EEDB),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Are you sure you want to leave the game?',
                        style: textStyle.copyWith(fontSize: 28),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          CustomButton(
                            backgroundColor: Color(0xff10A958),
                            text: 'Cancel',
                            fontSize: 32,
                            width: 140,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          CustomButton(
                            backgroundColor: Color(0xffFF2727),
                            text: 'Leave',
                            fontSize: 32,
                            width: 140,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                    currentUserId: store.user.id,
                    players: lobbyData.players,
                    remainingSeconds: _remainingSeconds,
                  ),
                  SizedBox(height: 20),
                  CountdownWidget(
                    durationInSeconds: lobbyData.startTime == null ? 3 : 0,
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

  int _getOpponentScore() {
    final store = context.read<Store>();
    final lobbyData = store.lobby;

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

  int _getPlayerScore() {
    final store = context.read<Store>();
    final lobbyData = store.lobby;

    final LobbyPlayerInfo? myPlayer = lobbyData.players[store.user.id];

    final int myScore = myPlayer?.score ?? _score;

    return myScore;
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
    final store = context.read<Store>();
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
        setState(() {
          _areAttemptsOver = true;
          _showCurrentWord = true;
        });

        // wait for 3 seconds
        await Future.delayed(const Duration(seconds: 3));

        setState(() {
          _showCurrentWord = false;
          _cursorPosition[0] = 0;
          _cursorPosition[1] = 0;
          _areAttemptsOver = false;
          _isCurrentRowFilled = false;
        });
        _selectWord();
        _initializeGameGrid();
      }
    }

    // update player progress in lobby
    // if the lobby doesnt exist this will just error out. can ignore that
    updatePlayerProgressInLobby(
      lobbyId: store.lobby.id,
      playerId: store.user.id,
      score: _getPlayerScore(),
      round: _currentRound,
      attempts: _cursorPosition[0] + 1,
    ).catchError((error) {
      print('Failed to update progress: $error');
    });
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

  void _handleTimeUp() async {
    final store = context.read<Store>();
    setState(() {
      _areAttemptsOver = true;
    });

    final lobbyData = store.lobby;

    final int myScore = _getPlayerScore();
    final int opponentScore = _getOpponentScore();

    //leave lobby
    await leaveLobby(lobbyId: lobbyData.id, playerId: store.user.id);
    //clear lobby in store
    store.lobby = getEmptyLobby();

    if (myScore > opponentScore) {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameWon.name,
        message: 'You win!',
        buttonText: 'Back to Menu',
        textSize: 28,
        buttonTextSize: 28,
        onClose: () {
          // reset lobby data
          store.lobby = getEmptyLobby();
          store.cancelLobbySubscription();
          Navigator.pushReplacementNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    } else if (myScore < opponentScore) {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameLost.name,
        message: 'You lost :(',
        buttonText: 'Back to Menu',
        textSize: 28,
        buttonTextSize: 28,
        onClose: () {
          // reset lobby data
          store.lobby = getEmptyLobby();
          store.cancelLobbySubscription();
          Navigator.pushReplacementNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    } else {
      CustomDialog.show(
        context,
        dialogKey: DialogKeys.gameTied.name,
        message: 'Game tied!',
        buttonText: 'Back to Menu',
        textSize: 28,
        buttonTextSize: 28,
        onClose: () {
          // reset lobby data
          store.lobby = getEmptyLobby();
          store.cancelLobbySubscription();
          Navigator.pushReplacementNamed(context, "/${Routes.mainmenu.name}");
        },
      );
    }

    // show updated ranks
  }

  /// Initialize the game grid based on lobby settings
  void _initializeGameGrid() {
    final store = context.read<Store>();
    final wordLength = store.lobby.wordLength;
    final maxAttempts = store.lobby.maxAttempts;

    _guessGrid = List.generate(
      maxAttempts,
      (_) => List.generate(wordLength, (_) => ""),
    );
  }

  // void _onStoreChanged() async {
  //   // get lobby from store
  //   final lobbyData = context.read<Store>().lobbyData;
  // }

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

  void _startGameTimer() async {
    final store = context.read<Store>();
    final localStartTime = DateTime.now();

    var lobbyStartTime = await getLobbyStartTime(lobbyId: store.lobby.id);
    late DateTime actualStartTime;

    if (lobbyStartTime == null) {
      // set lobby start time
      store.lobby.startTime = localStartTime;
      await setLobbyStartTime(
        lobbyId: store.lobby.id,
        startTime: localStartTime,
      );
      actualStartTime = localStartTime;
    } else {
      store.lobby.startTime = lobbyStartTime;
      actualStartTime = lobbyStartTime;
    }

    // Calculate initial remaining time based on actual lobby start time
    final initialElapsedTime = DateTime.now().difference(actualStartTime);
    setState(() {
      _remainingSeconds = _roundDuration - initialElapsedTime.inSeconds;
    });

    // If time is already up, handle it immediately
    if (_remainingSeconds <= 0) {
      _handleTimeUp();
      return;
    }

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedTime = DateTime.now().difference(actualStartTime);
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

  void _updateScore() {
    final store = context.read<Store>();
    final lobbyData = store.lobby;

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
}

// take action after time is up.
// compare score with opponent
// show winner
// show updated ranks
// go to main menu
