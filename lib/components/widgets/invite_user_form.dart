import 'package:flutter/material.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/ui/text_form_field.dart';

class InviteUserForm extends StatefulWidget {
  final Function(String) onInvite;

  const InviteUserForm({Key? key, required this.onInvite}) : super(key: key);

  @override
  State<InviteUserForm> createState() => _InviteUserFormState();
}

class _InviteUserFormState extends State<InviteUserForm> {
  final TextEditingController _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _userIdController.removeListener(_updateButtonState);
    _userIdController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _userIdController.text.trim().isNotEmpty;
    });
  }

  void _handleInvite() {
    if (_formKey.currentState!.validate()) {
      widget.onInvite(_userIdController.text.trim());
      _userIdController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextFormField(
            controller: _userIdController,
            // label: "User ID",
            helperText: "Enter user ID to invite",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a user ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _isButtonEnabled ? _handleInvite : null,
            disabled: !_isButtonEnabled,
            text: "Invite",
            backgroundColor: Color(0xff0099FF),
            width: 175,
            fontSize: 32,
          ),
        ],
      ),
    );
  }
}
