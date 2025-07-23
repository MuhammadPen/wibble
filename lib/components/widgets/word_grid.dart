import 'package:flutter/material.dart';
import 'package:wibble/styles/text.dart';

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
                      padding: EdgeInsets.symmetric(
                        vertical: isWordComplete && cursorPosition[0] == row
                            ? 10
                            : 5,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isWordComplete && cursorPosition[0] == row
                            ? Color(0xff0099FF).withValues(alpha: 1)
                            : Color(0xffF2EEDB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          for (var col = 0; col < guessGrid[row].length; col++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildCell(
                                row: row,
                                col: col,
                                size: boxSize,
                                textColor:
                                    isWordComplete && cursorPosition[0] == row
                                    ? Colors.white
                                    : Colors.black,
                                backgroundColor:
                                    isWordComplete && cursorPosition[0] == row
                                    ? Color(0xff0099FF)
                                    : _getCellBackgroundColor(row, col),
                              ),
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
  Widget _buildCell({
    required int row,
    required int col,
    required double size,
    Color? textColor,
    Color? backgroundColor,
  }) {
    final bool isActive = _isCurrentCell(row, col);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: isActive ? Color(0xff0099FF) : Colors.black),
        boxShadow: [
          BoxShadow(
            color: isActive ? Color.fromARGB(255, 0, 124, 206) : Colors.black,
            offset: Offset(-3, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          guessGrid[row][col],
          style: textStyle.copyWith(color: textColor),
        ),
      ),
    );
  }

  /// Get the background color for a cell based on Wordle rules
  Color _getCellBackgroundColor(int row, int col) {
    // Only apply coloring to completed rows (rows less than cursor row)
    if (row >= cursorPosition[0]) {
      return Color(0xffF2EEDB);
    }

    final String guessedLetter = guessGrid[row][col].toLowerCase();
    final String targetWordLower = targetWord.toLowerCase();

    // If the cell is empty, return transparent
    if (guessedLetter.isEmpty) {
      return Color(0xffF2EEDB);
    }

    // Check if letter is in correct position (green)
    if (col < targetWordLower.length && guessedLetter == targetWordLower[col]) {
      return Color(0xff10A958);
    }

    // Check if letter is in the word but wrong position (yellow)
    if (targetWordLower.contains(guessedLetter)) {
      return Color(0xffFFC700);
    }

    // Letter is not in the word (light grey)
    return Color(0xffB6B2A4);
  }

  /// Check if this cell is the current active cell
  bool _isCurrentCell(int row, int column) {
    return cursorPosition[0] == row && cursorPosition[1] == column;
  }
}
