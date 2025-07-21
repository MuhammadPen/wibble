import 'package:flutter/material.dart';
import 'package:wibble/components/ui/dialog.dart';
import 'package:wibble/types.dart';

class HowToPlayDialog {
  static final _dialogKey = DialogKeys.howToPlay.name;

  /// Hide the How to Play dialog
  static bool hide() {
    return CustomDialog.hide(_dialogKey);
  }

  /// Check if the How to Play dialog is currently open
  static bool isOpen() {
    return CustomDialog.isOpen(_dialogKey);
  }

  /// Show the How to Play dialog
  static Future<void> show(BuildContext context) {
    return CustomDialog.show(
      context,
      dialogKey: _dialogKey,
      message: _getGameExplanation(),
      buttonText: 'Got it!',
    );
  }

  /// Get the concise game explanation
  static String _getGameExplanation() {
    return '''🎯 Wibble - Word Guessing Showdown

⏱️ 3 minutes to guess as many words as possible
🎯 Each word: 5 letters, max 6 attempts
🌟 Scoring: 100 points for 1st try, decreasing each attempt
🏆 Highest score wins!

📝 How to play:
• Type letters using the keyboard
• Press ENTER to submit your guess
• Green = correct letter, correct position
• Yellow = correct letter, wrong position
• Gray = letter not in word

💡 Strategy: Guess faster with fewer attempts for more points!''';
  }
}
