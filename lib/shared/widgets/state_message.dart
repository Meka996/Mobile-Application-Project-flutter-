import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import 'velora_button.dart';

/// A themed message for empty, unavailable, or failed content.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : _isError = false;

  const StateMessage.error({
    super.key,
    required this.title,
    required VoidCallback onRetry,
    this.message,
    this.icon = Icons.error_outline,
    String retryLabel = 'Try again',
  }) : _isError = true,
       actionLabel = retryLabel,
       onAction = onRetry;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = actionLabel;
    final text = message;

    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(AppLayout.page),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: _isError ? scheme.error : scheme.primary,
              ),
              const SizedBox(height: AppLayout.large),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (text != null) ...[
                const SizedBox(height: AppLayout.small),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (label != null && onAction != null) ...[
                const SizedBox(height: AppLayout.page),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: VeloraButton(
                    text: label,
                    onPressed: onAction,
                    outlined: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
