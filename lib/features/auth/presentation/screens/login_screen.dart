import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/auth_service.dart';
import '../../../../core/widgets/velora_text_field.dart';
import '../../../../core/widgets/velora_button.dart';
import '../../../../core/theme/app_theme.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_email.trim().isEmpty || _password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _email,
        password: _password,
      );

      if (!mounted) return;
      _showMessage('Login successful!');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _showMessage('No account found. Check your email and password.');
      } else if (e.code == 'wrong-password') {
        _showMessage('Incorrect password.');
      } else if (e.code == 'invalid-email') {
        _showMessage('Please enter a valid email.');
      } else {
        _showMessage(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.deepRose,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const Text(
            'Welcome Back to VELORA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepRose,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Login to continue shopping.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          VeloraTextField(
            hint: 'Email Address',
            icon: Icons.email_outlined,
            onChanged: (value) => _email = value,
          ),
          const SizedBox(height: 20),
          VeloraTextField(
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            onChanged: (value) => _password = value,
          ),
          const SizedBox(height: 30),
          VeloraButton(
            text: _isLoading ? 'Logging in...' : 'Login',
            icon: Icons.login,
            onPressed: _isLoading ? null : _login,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: _isLoading ? null : _openSignUp,
                child: const Text(
                  'Sign Up',
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
