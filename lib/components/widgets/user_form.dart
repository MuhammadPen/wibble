import 'package:flutter/material.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/ui/shadow_container.dart';

class UserFormDialog extends StatefulWidget {
  final Function(String username)? onSubmit;
  final bool dismissible;

  const UserFormDialog({Key? key, this.onSubmit, this.dismissible = false})
    : super(key: key);

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();

  // Static method to show the dialog
  static Future<String?> show(
    BuildContext context, {
    Function(String username)? onSubmit,
    bool dismissible = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: dismissible, // Uses the dismissible parameter
      builder: (BuildContext context) {
        return UserFormDialog(onSubmit: onSubmit, dismissible: dismissible);
      },
    );
  }
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSubmitEnabled = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.dismissible, // Uses the dismissible parameter
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        content: ShadowContainer(
          backgroundColor: Color(0xffF2EEDB),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Text(
                "Username",
                style: TextStyle(fontSize: 32, fontFamily: "Baloo"),
              ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildUsernameField()],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  if (widget.dismissible)
                    CustomButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: "Cancle",
                      fontSize: 32,
                      width: 140,
                      backgroundColor: Color(0xffFF2727),
                    ),
                  CustomButton(
                    onPressed: _isSubmitEnabled ? _handleSubmit : null,
                    text: "Submit",
                    fontSize: 32,
                    width: 140,
                    backgroundColor: Color(0xff10A958),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //   Text(
  //   'Enter Your Information',
  //   style: TextStyle(
  //     color: Colors.white,
  //     fontSize: 24,
  //     fontFamily: "Baloo",
  //   ),
  // ),

  // ElevatedButton(
  //           onPressed: _isSubmitEnabled ? _handleSubmit : null,
  //           child: const Text('Submit'),
  //         ),

  @override
  void dispose() {
    _usernameController.removeListener(_updateSubmitButtonState);
    _usernameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateSubmitButtonState);
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      autofocus: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: "Baloo"),
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

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text.trim();
      Navigator.of(context).pop(username); // Only way to dismiss the dialog
      widget.onSubmit?.call(username);
    }
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
