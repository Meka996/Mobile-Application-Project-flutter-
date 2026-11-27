import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';
import 'package:velora/core/widgets/velora_button.dart';

/// Centered spinner shown while Firestore data is loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.deepRose),
    );
  }
}

/// Reusable empty / error / guest message with an optional action button.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;
    final text = message;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppTheme.blushPink),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepRose,
              ),
            ),
            if (text != null) ...[
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            if (label != null && action != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: VeloraButton(text: label, onPressed: action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
