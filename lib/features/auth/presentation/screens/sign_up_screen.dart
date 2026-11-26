import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/widgets/velora_text_field.dart';
import '../../../../core/widgets/velora_button.dart';
import '../../../../core/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _confirmPassword = '';

  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_name.trim().isEmpty || _email.trim().isEmpty || _password.isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (_name.trim().length > 80) {
      _showMessage('Name must be 80 characters or less.');
      return;
    }

    if (!_email.contains('@') || !_email.contains('.')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (_password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (_password != _confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUp(
        name: _name.trim(),
        email: _email.trim(),
        password: _password,
        phone: _phone.trim(),
      );

      if (!mounted) return;

      _showMessage('Account created successfully!');

      // AuthGate handles the authenticated state.
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
    } catch (e) {
      if (!mounted) return;

      if (FirebaseAuth.instance.currentUser != null) {
        _showMessage(
          'Account created, but profile could not be saved. Please retry.',
        );
      } else {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
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

  void _goToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,

      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppTheme.offWhite,
        foregroundColor: AppTheme.deepRose,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 15),

          const Text(
            'Welcome to VELORA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepRose,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Create your account and start exploring.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          VeloraTextField(
            hint: 'Full Name',
            icon: Icons.person_outline,
            onChanged: (value) => _name = value,
          ),

          const SizedBox(height: 16),

          VeloraTextField(
            hint: 'Email Address',
            icon: Icons.email_outlined,
            onChanged: (value) => _email = value,
          ),

          const SizedBox(height: 16),

          VeloraTextField(
            hint: 'Phone Number (Optional)',
            icon: Icons.phone_outlined,
            onChanged: (value) => _phone = value,
          ),

          const SizedBox(height: 16),

          VeloraTextField(
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            onChanged: (value) => _password = value,
          ),

          const SizedBox(height: 16),

          VeloraTextField(
            hint: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true,
            onChanged: (value) => _confirmPassword = value,
          ),

          const SizedBox(height: 25),

          VeloraButton(
            text: _isLoading ? 'Creating Account...' : 'Sign Up',
            icon: Icons.person_add_outlined,
            onPressed: _isLoading ? null : _signUp,
          ),

          const SizedBox(height: 20),

          // Navigate back to Login Screen
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 14),
              ),

              TextButton(
                onPressed: _isLoading ? null : _goToLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: AppTheme.deepRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
