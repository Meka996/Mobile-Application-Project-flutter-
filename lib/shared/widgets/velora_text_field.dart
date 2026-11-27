import 'package:flutter/material.dart';

class VeloraTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;

  const VeloraTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.controller,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(labelText: hint, prefixIcon: Icon(icon)),
    );
  }
}
