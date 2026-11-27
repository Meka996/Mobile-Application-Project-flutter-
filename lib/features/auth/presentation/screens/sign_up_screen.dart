import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../shared/shared.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.authService, this.onRegistrationPending});

  final AuthService? authService;
  final ValueChanged<bool>? onRegistrationPending;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';

  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    widget.onRegistrationPending?.call(true);

    try {
      await _authService.signUp(
        name: _name.trim(),
        email: _email.trim(),
        password: _password,
        phone: _phone.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        _showMessage('This email is already registered.');
      } else if (e.code == 'weak-password') {
        _showMessage('Please choose a stronger password.');
      } else if (e.code == 'invalid-email') {
        _showMessage('Invalid email address.');
      } else {
        _showMessage(e.message ?? 'Registration failed.');
      }
    } catch (_) {
      if (!mounted) return;

      if (_authService.hasPendingRegistration) {
        _showMessage(
          'Account created, but profile could not be saved. Please retry.',
        );
      } else {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        widget.onRegistrationPending?.call(_authService.hasPendingRegistration);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _goToLogin() async {
    if (_authService.hasPendingRegistration) {
      setState(() => _isLoading = true);
      try {
        await _authService.logout();
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Could not return to Login. Please try again.');
        }
        return;
      }
      if (!mounted) return;
      widget.onRegistrationPending?.call(false);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final needsProfileRetry = _authService.hasPendingRegistration;
    return PopScope(
      canPop: !_isLoading && !needsProfileRetry,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppLayout.page),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const SizedBox(height: AppLayout.large),
                  const VeloraLogo(greeting: 'Welcome to'),

                  const SizedBox(height: AppLayout.small),

                  const Text(
                    'Create your account and start exploring.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppLayout.section),

                  VeloraTextField(
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final name = (value ?? '').trim();
                      if (name.isEmpty) return 'Enter your name.';
                      if (name.length > 80) return 'Use 80 characters or less.';
                      return null;
                    },
                    onChanged: (value) => _name = value,
                  ),

                  const SizedBox(height: 16),

                  VeloraTextField(
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    enabled: !needsProfileRetry,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      return email.contains('@') && email.contains('.')
                          ? null
                          : 'Enter a valid email address.';
                    },
                    onChanged: (value) => _email = value,
                  ),

                  const SizedBox(height: 16),

                  VeloraTextField(
                    hint: 'Phone Number (Optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _phone = value,
                  ),

                  const SizedBox(height: 16),

                  VeloraTextField(
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    enabled: !needsProfileRetry,
                    validator: (value) => (value ?? '').length < 6
                        ? 'Use at least 6 characters.'
                        : null,
                    onChanged: (value) => _password = value,
                  ),

                  const SizedBox(height: 16),

                  VeloraTextField(
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: !needsProfileRetry,
                    validator: (value) =>
                        value == _password ? null : 'Passwords do not match.',
                  ),

                  const SizedBox(height: AppLayout.page),

                  VeloraButton(
                    text: _isLoading
                        ? 'Creating Account...'
                        : needsProfileRetry
                        ? 'Retry Saving Profile'
                        : 'Sign Up',
                    icon: Icons.person_add_outlined,
                    onPressed: _isLoading ? null : _signUp,
                  ),

                  const SizedBox(height: AppLayout.large),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (!needsProfileRetry)
                        const Text('Already have an account?'),

                      TextButton(
                        onPressed: _isLoading ? null : _goToLogin,
                        child: Text(
                          needsProfileRetry ? 'Back to Login' : 'Login',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
