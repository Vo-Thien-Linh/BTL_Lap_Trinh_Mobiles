import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}