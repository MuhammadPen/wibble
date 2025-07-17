import 'package:flutter/material.dart';

class UserFormDialog extends StatefulWidget {
  final Function(String username) onSubmit;

  const UserFormDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();

  // Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required Function(String username) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents dismissal by tapping outside
      builder: (BuildContext context) {
        return UserFormDialog(onSubmit: onSubmit);
      },
    );
  }
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSubmitEnabled = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateSubmitButtonState);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_updateSubmitButtonState);
    _usernameController.dispose();
    super.dispose();
  }

  void _updateSubmitButtonState() {
    final username = _usernameController.text.trim();
    final isValid = username.isNotEmpty;

    if (isValid != _isSubmitEnabled) {
      setState(() {
        _isSubmitEnabled = isValid;
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text.trim();
      Navigator.of(context).pop(); // Only way to dismiss the dialog
      widget.onSubmit(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents back button dismissal
      child: AlertDialog(
        title: const Text('Enter Your Information'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username field
              _buildUsernameField(),

              // Space for future fields can be added here easily
              // Example: _buildEmailField(),
              // Example: _buildAgeField(),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _isSubmitEnabled ? _handleSubmit : null,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Username is required';
        }
        if (value.trim().length < 3) {
          return 'Username must be at least 3 characters';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (_isSubmitEnabled) {
          _handleSubmit();
        }
      },
    );
  }

  // Example of how to add future fields - just uncomment and modify as needed
  /*
  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          // Add email validation logic here
          return null;
        },
      ),
    );
  }
  */
}
