import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  // Static map to track open dialogs by their keys
  static final Map<String, BuildContext> _openDialogs =
      <String, BuildContext>{};
  final String message;
  final VoidCallback? onClose;
  final String buttonText;

  final String dialogKey;

  const CustomDialog({
    Key? key,
    required this.message,
    required this.dialogKey,
    this.onClose,
    this.buttonText = 'Close',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _openDialogs.remove(dialogKey);
            if (onClose != null) {
              onClose!();
            }
          },
          child: Text(buttonText),
        ),
      ],
    );
  }

  // Static method to get all open dialog keys
  static List<String> getOpenDialogKeys() {
    return _openDialogs.keys.toList();
  }

  // Static method to hide a specific dialog by key
  static bool hide(String dialogKey) {
    final dialogContext = _openDialogs[dialogKey];
    if (dialogContext != null && Navigator.canPop(dialogContext)) {
      Navigator.of(dialogContext).pop();
      _openDialogs.remove(dialogKey);
      return true; // Successfully closed
    }
    return false; // Dialog not found or couldn't be closed
  }

  // Static method to hide all open dialogs
  static void hideAll() {
    final keys = _openDialogs.keys.toList();
    for (final key in keys) {
      hide(key);
    }
  }

  // Static method to check if a dialog with specific key is open
  static bool isOpen(String dialogKey) {
    return _openDialogs.containsKey(dialogKey);
  }

  // Static method to show the dialog with a unique key
  static Future<void> show(
    BuildContext context, {
    required String dialogKey,
    required String message,
    VoidCallback? onClose,
    String buttonText = 'Close',
    bool barrierDismissible = true,
  }) {
    // If dialog with this key already exists, don't create another
    if (_openDialogs.containsKey(dialogKey)) {
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        // Store the dialog context with its key
        _openDialogs[dialogKey] = dialogContext;

        return PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              // Remove from tracking when dialog is dismissed
              _openDialogs.remove(dialogKey);
            }
          },
          child: CustomDialog(
            message: message,
            dialogKey: dialogKey,
            onClose: onClose,
            buttonText: buttonText,
          ),
        );
      },
    ).then((_) {
      // Ensure cleanup when dialog completes
      _openDialogs.remove(dialogKey);
    });
  }
}
