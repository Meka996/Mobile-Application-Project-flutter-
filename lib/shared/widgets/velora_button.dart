import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';

class VeloraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  const VeloraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppLayout.small,
      runSpacing: AppLayout.small,
      children: [
        if (icon != null) Icon(icon),
        Text(text, textAlign: TextAlign.center),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, child: label)
          : ElevatedButton(onPressed: onPressed, child: label),
    );
  }
}
