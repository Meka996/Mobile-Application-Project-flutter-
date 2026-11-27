import 'package:flutter/material.dart';

class VeloraLogo extends StatelessWidget {
  const VeloraLogo({super.key, this.greeting});

  final String? greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = greeting;
    final style = prefix == null
        ? theme.textTheme.headlineSmall
        : theme.textTheme.headlineMedium;

    return Text(
      prefix == null ? 'VELORA' : '$prefix VELORA',
      textAlign: TextAlign.center,
      style: style?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: prefix == null ? 3 : null,
      ),
    );
  }
}
