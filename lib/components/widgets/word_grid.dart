import 'package:flutter/material.dart';

class WordGrid extends StatelessWidget {
  final List<List<String>> guessGrid;

  final List<int> cursorPosition;
  final bool isWordComplete;
  final String targetWord;
  const WordGrid({
    super.key,
    required this.guessGrid,
    required this.cursorPosition,
    required this.isWordComplete,
    required this.targetWord,
  });

  @override
  Widget build(BuildContext context) {
    final wordLength = guessGrid[0].length;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate box size based on available width and word length
          final double totalSpacing = (wordLength - 1) * 10;
          double boxSize = (constraints.maxWidth - totalSpacing) / wordLength;
          boxSize = boxSize.clamp(20.0, 50.0);

          return Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var row = 0; row < guessGrid.length; row++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isWordComplete && cursorPosition[0] == row
                            ? Colors.blueAccent.withValues(alpha: 0.8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          for (var col = 0; col < guessGrid[row].length; col++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildCell(row, col, boxSize),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build an individual cell in the word grid
  Widget _buildCell(int row, int col, double size) {
    final bool isActive = _isCurrentCell(row, col);
    final Color backgroundColor = _getCellBackgroundColor(row, col);
    final Color textColor = _getCellTextColor(row, col);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.blue : Colors.black,
          width: isActive ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(isActive ? 12 : 4),
        color: isActive ? Colors.blue.withValues(alpha: 0.1) : backgroundColor,
      ),
      child: Center(
        child: Text(
          guessGrid[row][col],
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// Get the background color for a cell based on Wordle rules
  Color _getCellBackgroundColor(int row, int col) {
    // Only apply coloring to completed rows (rows less than cursor row)
    if (row >= cursorPosition[0]) {
      return Colors.transparent;
    }

    final String guessedLetter = guessGrid[row][col].toLowerCase();
    final String targetWordLower = targetWord.toLowerCase();

    // If the cell is empty, return transparent
    if (guessedLetter.isEmpty) {
      return Colors.transparent;
    }

    // Check if letter is in correct position (green)
    if (col < targetWordLower.length && guessedLetter == targetWordLower[col]) {
      return Colors.green.withValues(alpha: 0.8);
    }

    // Check if letter is in the word but wrong position (yellow)
    if (targetWordLower.contains(guessedLetter)) {
      return Colors.yellow.withValues(alpha: 0.8);
    }

    // Letter is not in the word (light grey)
    return Colors.grey[300]!;
  }

  /// Get the text color for a cell based on background
  Color _getCellTextColor(int row, int col) {
    final backgroundColor = _getCellBackgroundColor(row, col);

    // Use white text for colored backgrounds, black for transparent
    if (backgroundColor == Colors.transparent) {
      return Colors.black;
    }
    return Colors.white;
  }

  /// Check if this cell is the current active cell
  bool _isCurrentCell(int row, int column) {
    return cursorPosition[0] == row && cursorPosition[1] == column;
  }
}
