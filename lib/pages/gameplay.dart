import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/components/keyboard_widget.dart';
import 'package:wibble/components/word_grid.dart';
import 'package:wibble/main.dart';
import 'dart:async';

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
  int _remainingSeconds = 180; // 3 minutes = 180 seconds
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

  void _handleTimeUp() {
    // Handle what happens when 3 minutes are up
    // For now, we'll just prevent further input
    // You can customize this based on your game rules
    setState(() {
      _areAttemptsOver = true;
    });

    // Show a dialog or navigate to results screen
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: Text('Game finished! Your final score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to main menu
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
    final maxAttempts = context.read<Store>().lobbyData["maxAttempts"] as int;
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
    final wordLength = appStore.lobbyData["wordLength"] as int;
    final maxAttempts = appStore.lobbyData["maxAttempts"] as int;

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
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: Colors.grey[100],
          appBar: AppBar(title: const Text('Wibble')),
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Word grid display
                  WordGrid(
                    guessGrid: _guessGrid,
                    cursorPosition: _cursorPosition,
                    isWordComplete: _isCurrentWordComplete,
                    targetWord: _currentWord,
                  ),
                  Text(_currentWord),
                  Text(_currentRound.toString()),
                  Text(_score.toString()),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 18,
                      color: _remainingSeconds <= 30
                          ? Colors.red
                          : Colors.black,
                    ),
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
