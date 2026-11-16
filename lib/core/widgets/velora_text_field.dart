import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VeloraTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const VeloraTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.deepRose),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.babyPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.deepRose, width: 2),
        ),
      ),
    );
  }
}
