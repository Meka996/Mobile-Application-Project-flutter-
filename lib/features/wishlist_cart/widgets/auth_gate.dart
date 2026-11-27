import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:velora/shared/shared.dart';

/// Shows [signedInBuilder] for a signed-in user and a friendly "please sign
/// in" screen for guests, so we never write to `users/null/...`.
///
/// It listens to auth changes, so the screen updates by itself after login or
/// logout. Routing to the real sign-in screen belongs to the Core/Auth owners:
/// pass [onSignInRequested] and it becomes the button's action.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.signedInBuilder,
    this.onSignInRequested,
    this.guestTitle = 'Sign in required',
    this.guestMessage = 'Please sign in to use this feature.',
    this.auth,
  });

  final Widget Function(BuildContext context) signedInBuilder;
  final VoidCallback? onSignInRequested;
  final String guestTitle;
  final String guestMessage;
  final FirebaseAuth? auth;

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = auth ?? FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      initialData: firebaseAuth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return StateMessage(
            icon: Icons.lock_outline,
            title: guestTitle,
            message: guestMessage,
            actionLabel: onSignInRequested == null ? null : 'Sign in',
            onAction: onSignInRequested,
          );
        }
        // The key makes Flutter rebuild the content if another user signs in.
        return KeyedSubtree(
          key: ValueKey(user.uid),
          child: signedInBuilder(context),
        );
      },
    );
  }
}
