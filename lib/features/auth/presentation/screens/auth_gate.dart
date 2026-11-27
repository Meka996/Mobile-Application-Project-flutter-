import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../../data/auth_service.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService, required this.signedInBuilder});

  final AuthService? authService;
  final WidgetBuilder signedInBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService = widget.authService ?? AuthService();
  late Stream<User?> _authChanges = _authService.authStateChanges();
  var _navigatorKey = GlobalKey<NavigatorState>();
  String? _navigatorUid;
  bool _registrationPending = false;

  void _openSignUp() {
    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpScreen(
          authService: _authService,
          onRegistrationPending: (pending) {
            setState(() => _registrationPending = pending);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: StateMessage.error(
              title: 'Unable to check your sign-in status.',
              onRetry: () => setState(() {
                _authChanges = _authService.authStateChanges();
              }),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingWidget(label: 'Checking sign-in'));
        }

        final uid = _registrationPending ? null : snapshot.data?.uid;
        if (_navigatorUid != uid) {
          _navigatorUid = uid;
          _navigatorKey = GlobalKey<NavigatorState>();
        }

        // Each session owns its routes, so auth changes also close pushed screens.
        return NavigatorPopHandler<Object?>(
          key: ValueKey(uid),
          onPopWithResult: (result) =>
              _navigatorKey.currentState?.maybePop(result),
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: uid == null
                  ? (_) => LoginScreen(
                      authService: _authService,
                      onSignUp: _openSignUp,
                    )
                  : widget.signedInBuilder,
            ),
          ),
        );
      },
    );
  }
}
