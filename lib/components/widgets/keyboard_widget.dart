import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/styles/text.dart';

class KeyboardWidget extends StatefulWidget {
  final Function(String) onKeyTap;
  final Function() onDelete;
  final Function() onEnter;
  final bool isCurrentWordComplete;

  const KeyboardWidget({
    super.key,
    required this.onKeyTap,
    required this.onDelete,
    required this.onEnter,
    required this.isCurrentWordComplete,
  });

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  late final FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeyboardRow([
                'Q',
                'W',
                'E',
                'R',
                'T',
                'Y',
                'U',
                'I',
                'O',
                'P',
              ], constraints),
              const SizedBox(height: 8),
              _buildKeyboardRow([
                'A',
                'S',
                'D',
                'F',
                'G',
                'H',
                'J',
                'K',
                'L',
              ], constraints),
              const SizedBox(height: 8),
              _buildBottomRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M'], constraints),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Widget _buildBottomRow(List<String> letters, BoxConstraints constraints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSpecialKey(
          'DELETE',
          constraints,
          widget.onDelete,
          Icons.backspace,
          widget.isCurrentWordComplete,
        ),
        const SizedBox(width: 2),
        ...letters.map((letter) => _buildKey(letter, constraints)),
        const SizedBox(width: 2),
        _buildSpecialKey(
          'ENTER',
          constraints,
          widget.onEnter,
          Icons.next_plan_outlined,
          widget.isCurrentWordComplete,
        ),
      ],
    );
  }

  Widget _buildKey(String letter, BoxConstraints constraints) {
    // Calculate key width based on available width
    final keyWidth = (constraints.maxWidth / 10) - 4;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        width: keyWidth,
        height: keyWidth * 1.5,
        child: CustomButton(
          onPressed: () => widget.onKeyTap(letter),
          borderRadius: 10,
          child: Center(
            child: Text(letter, style: textStyle.copyWith(fontSize: 28)),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> letters, BoxConstraints constraints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters
          .map((letter) => _buildKey(letter, constraints))
          .toList(),
    );
  }

  Widget _buildSpecialKey(
    String keyType,
    BoxConstraints constraints,
    Function() onPressed,
    IconData icon,
    bool isCurrentWordComplete,
  ) {
    final isEnterkey = keyType == 'ENTER';

    // Calculate key width based on available width - make special keys wider
    final keyWidth = (constraints.maxWidth / 7) - 4;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        width: keyWidth,
        height: keyWidth,
        child: CustomButton(
          loadingSize: 5,
          onPressed: isEnterkey && !isCurrentWordComplete ? null : onPressed,
          disabled: isEnterkey && !isCurrentWordComplete,
          backgroundColor: isEnterkey && isCurrentWordComplete
              ? Color(0xff0099FF)
              : Colors.white,
          child: Center(
            child: Icon(
              icon,
              size: 25,
              color: isEnterkey && isCurrentWordComplete ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final keyLabel = event.logicalKey.keyLabel;

      // Handle letters (A-Z)
      if (keyLabel.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(keyLabel)) {
        widget.onKeyTap(keyLabel.toUpperCase());
      }
      // Handle Enter key
      else if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onEnter();
      }
      // Handle Backspace key
      else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        widget.onDelete();
      }
    }
  }
}
