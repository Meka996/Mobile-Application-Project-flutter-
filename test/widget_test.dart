import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/core/theme/app_theme.dart';
import 'package:velora/features/auth/data/auth_service.dart';
import 'package:velora/features/auth/presentation/screens/auth_gate.dart';

void main() {
  testWidgets('validation and auth changes discard the previous route stack', (
    tester,
  ) async {
    final auth = _TestAuthService();
    addTearDown(auth.changes.close);
    await _startApp(tester, auth);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(auth.loginCalls, 0);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    tester.testTextInput.hide();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(auth.loginCalls, 1);
    expect(find.text('Signed-in home'), findsOneWidget);

    await tester.tap(find.text('Open protected route'));
    await tester.pumpAndSettle();
    expect(find.text('Protected screen'), findsOneWidget);

    auth.changes.add(_TestUser('another-student'));
    await tester.pumpAndSettle();
    expect(find.text('Protected screen'), findsNothing);
    await tester.tap(find.text('Open protected route'));
    await tester.pumpAndSettle();
    expect(find.text('Protected screen'), findsOneWidget);

    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.text('Protected screen'), findsNothing);
    expect(find.text('Welcome Back to VELORA'), findsOneWidget);
  });

  testWidgets(
    'sign-up waits for profile creation and can retry a failed write',
    (tester) async {
      final auth = _TestAuthService();
      addTearDown(auth.changes.close);
      await _startApp(tester, auth);

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Velora Student');
      await tester.enterText(fields.at(1), 'student@example.com');
      await tester.ensureVisible(fields.at(3));
      await tester.enterText(fields.at(3), 'password');
      await tester.ensureVisible(fields.at(4));
      await tester.enterText(fields.at(4), 'mismatch');
      final signUp = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUp);
      await tester.tap(signUp);
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(auth.signUpCalls, 0);

      await tester.enterText(fields.at(4), 'password');
      await tester.ensureVisible(signUp);
      await tester.tap(signUp);
      await tester.pumpAndSettle();
      expect(auth.signUpCalls, 1);
      expect(find.text('Signed-in home'), findsNothing);

      auth.profileWrite.completeError(StateError('profile write failed'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Account created, but profile could not be saved. Please retry.',
        ),
        findsOneWidget,
      );
      final retry = find.widgetWithText(ElevatedButton, 'Retry Saving Profile');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      auth.profileWrite.complete();
      await tester.pumpAndSettle();
      expect(auth.signUpCalls, 2);
      expect(auth.accountsCreated, 1);
      expect(find.text('Signed-in home'), findsOneWidget);
      expect(find.text('Create Account'), findsNothing);
    },
  );
}

Future<void> _startApp(WidgetTester tester, _TestAuthService auth) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: AuthGate(
        authService: auth,
        signedInBuilder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Signed-in home')),
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Protected screen')),
              ),
            ),
            child: const Text('Open protected route'),
          ),
        ),
      ),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  auth.changes.add(null);
  await tester.pumpAndSettle();
}

class _TestAuthService extends AuthService {
  final changes = StreamController<User?>();
  var profileWrite = Completer<void>();
  var loginCalls = 0;
  var signUpCalls = 0;
  var accountsCreated = 0;
  var _pendingRegistration = false;

  @override
  Stream<User?> authStateChanges() => changes.stream;

  @override
  bool get hasPendingRegistration => _pendingRegistration;

  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    changes.add(_TestUser());
    return _TestCredential();
  }

  @override
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    signUpCalls++;
    if (!_pendingRegistration) {
      accountsCreated++;
      _pendingRegistration = true;
      changes.add(_TestUser());
    }
    if (profileWrite.isCompleted) profileWrite = Completer<void>();
    await profileWrite.future;
    _pendingRegistration = false;
    return _TestCredential();
  }

  @override
  Future<void> logout() async => changes.add(null);
}

class _TestUser implements User {
  _TestUser([this.uid = 'student']);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
