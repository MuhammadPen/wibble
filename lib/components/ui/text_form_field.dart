import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final bool? autoFocus;
  final String? label;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String?)? onFieldSubmitted;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.autoFocus = false,
    this.label = "",
    this.helperText = "",
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autoFocus ?? false,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 16, fontFamily: "Baloo"),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: "Baloo"),
    );
  }
}

// TextFormField(
//       controller: _usernameController,
//       autofocus: true,
//       decoration: InputDecoration(
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: "Baloo"),
//       validator: (value) {
//         if (value == null || value.trim().isEmpty) {
//           return 'Username is required';
//         }
//         if (value.trim().length < 3) {
//           return 'Username must be at least 3 characters';
//         }
//         return null;
//       },
//       textInputAction: TextInputAction.done,
//       onFieldSubmitted: (_) {
//         if (_isSubmitEnabled) {
//           _handleSubmit();
//         }
//       },
//     )
